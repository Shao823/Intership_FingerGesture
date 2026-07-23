#include "emg_dma.h"

#include "xil_cache.h"
#include "xparameters.h"

#define EMG_DMA_RESET_TIMEOUT_ITERATIONS 100000000U

static void EmgDma_InterruptHandler(void *callback_ref)
{
    EmgDma *dma = (EmgDma *)callback_ref;
    const u32 irq_status = XAxiDma_IntrGetIrq(
        &dma->instance,
        XAXIDMA_DMA_TO_DEVICE
    );
    const u32 handled_mask = XAXIDMA_IRQ_IOC_MASK | XAXIDMA_IRQ_ERROR_MASK;

    if ((irq_status & handled_mask) == 0U) {
        return;
    }

    XAxiDma_IntrAckIrq(
        &dma->instance,
        irq_status & handled_mask,
        XAXIDMA_DMA_TO_DEVICE
    );

    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK) != 0U) {
        dma->error_status |= irq_status & XAXIDMA_IRQ_ERROR_MASK;
        dma->active = 0U;
    }

    if ((irq_status & XAXIDMA_IRQ_IOC_MASK) != 0U) {
        dma->active = 0U;
        dma->completed_count++;
    }

    if (dma->event_handler != NULL) {
        dma->event_handler(dma->callback_ref, irq_status & handled_mask);
    }
}

XStatus EmgDma_Initialize(EmgDma *dma)
{
    XAxiDma_Config *config;
    u32 timeout;

    if (dma == NULL) {
        return XST_FAILURE;
    }

    config = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
    if (config == NULL) {
        return XST_FAILURE;
    }

    if (XAxiDma_CfgInitialize(&dma->instance, config) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&dma->instance)) {
        return XST_FAILURE;
    }

    dma->active = 0U;
    dma->completed_count = 0U;
    dma->error_status = 0U;
    dma->event_handler = NULL;
    dma->callback_ref = NULL;

    XAxiDma_Reset(&dma->instance);
    for (timeout = 0U; timeout < EMG_DMA_RESET_TIMEOUT_ITERATIONS; ++timeout) {
        if (XAxiDma_ResetIsDone(&dma->instance)) {
            break;
        }
    }
    if (timeout == EMG_DMA_RESET_TIMEOUT_ITERATIONS) {
        return XST_FAILURE;
    }

    EmgDma_DisableInterrupts(dma);
    XAxiDma_IntrAckIrq(
        &dma->instance,
        XAXIDMA_IRQ_ALL_MASK,
        XAXIDMA_DMA_TO_DEVICE
    );
    return XST_SUCCESS;
}

XStatus EmgDma_ConnectInterrupt(
    EmgDma *dma,
    XScuGic *interrupt_controller,
    u32 interrupt_id,
    EmgDmaEventHandler event_handler,
    void *callback_ref
)
{
    if (dma == NULL || interrupt_controller == NULL) {
        return XST_FAILURE;
    }

    dma->event_handler = event_handler;
    dma->callback_ref = callback_ref;

    XScuGic_SetPriorityTriggerType(
        interrupt_controller,
        interrupt_id,
        0xA0U,
        0x1U
    );
    return XScuGic_Connect(
        interrupt_controller,
        interrupt_id,
        (Xil_InterruptHandler)EmgDma_InterruptHandler,
        dma
    );
}

void EmgDma_EnableInterrupts(EmgDma *dma)
{
    XAxiDma_IntrEnable(
        &dma->instance,
        XAXIDMA_IRQ_IOC_MASK | XAXIDMA_IRQ_ERROR_MASK,
        XAXIDMA_DMA_TO_DEVICE
    );
}

void EmgDma_DisableInterrupts(EmgDma *dma)
{
    XAxiDma_IntrDisable(
        &dma->instance,
        XAXIDMA_IRQ_ALL_MASK,
        XAXIDMA_DMA_TO_DEVICE
    );
}

XStatus EmgDma_StartMm2s(EmgDma *dma, const void *buffer, u32 byte_count)
{
    XStatus status;

    if (dma == NULL || buffer == NULL || byte_count == 0U) {
        return XST_FAILURE;
    }
    if ((((UINTPTR)buffer) & 0x3U) != 0U || dma->active != 0U) {
        return XST_FAILURE;
    }

    Xil_DCacheFlushRange((UINTPTR)buffer, byte_count);
    dma->active = 1U;
    status = XAxiDma_SimpleTransfer(
        &dma->instance,
        (UINTPTR)buffer,
        byte_count,
        XAXIDMA_DMA_TO_DEVICE
    );
    if (status != XST_SUCCESS) {
        dma->active = 0U;
    }
    return status;
}

u32 EmgDma_ReadStatus(const EmgDma *dma)
{
    return XAxiDma_ReadReg(
        dma->instance.RegBase,
        XAXIDMA_SR_OFFSET
    );
}
