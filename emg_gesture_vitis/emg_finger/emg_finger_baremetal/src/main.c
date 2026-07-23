#include "emg_accelerator.h"
#include "emg_dma.h"
#include "emg_testdata.h"

#include "xil_cache.h"
#include "xil_exception.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xscugic.h"
#include "xstatus.h"

#define EMG_PIPELINE_TIMEOUT_ITERATIONS 1000000000U

#define EMG_PIPELINE_ERROR_DMA             0x00000001U
#define EMG_PIPELINE_ERROR_ACCELERATOR     0x00000002U
#define EMG_PIPELINE_ERROR_RESULT          0x00000004U
#define EMG_PIPELINE_ERROR_CYCLE_COUNT    0x00000008U
#define EMG_PIPELINE_ERROR_COUNT           0x00000010U
#define EMG_PIPELINE_ERROR_NO_OVERLAP      0x00000020U
#define EMG_PIPELINE_ERROR_NO_QUEUE        0x00000040U

typedef struct {
    u32 irq_status;
    u32 dma_status;
    u32 accelerator_status;
    u32 rx_status;
} EmgDmaObservation;

typedef struct {
    u32 status;
    u32 result;
    u32 rx_status;
    u32 error_status;
    u32 cycle_count;
} EmgInferenceObservation;

typedef struct {
    volatile u32 dma_started;
    volatile u32 dma_completed;
    volatile u32 accelerator_completed;
    volatile u32 accelerator_irq_count;
    volatile u32 dma_while_busy_count;
    volatile u32 queued_frame_count;
    volatile u32 autostart_overlap_count;
    volatile u32 error_flags;
    volatile u32 finished;
    volatile u32 passed;
    volatile EmgDmaObservation dma_observations[EMG_TEST_FRAME_COUNT];
    volatile EmgInferenceObservation inference_observations[
        EMG_TEST_FRAME_COUNT
    ];
} EmgPipelineState;

static EmgDma g_dma;
static XScuGic g_interrupt_controller;
static EmgPipelineState g_pipeline;

static void DmaEventHandler(void *callback_ref, u32 irq_status)
{
    EmgPipelineState *pipeline = (EmgPipelineState *)callback_ref;
    const u32 observation_index = g_dma.completed_count - 1U;
    const u32 accelerator_status = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_STATUS_OFFSET
    );
    const u32 rx_status = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_RX_STATUS_OFFSET
    );

    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK) != 0U) {
        pipeline->error_flags |= EMG_PIPELINE_ERROR_DMA;
    }

    if ((irq_status & XAXIDMA_IRQ_IOC_MASK) == 0U) {
        return;
    }

    pipeline->dma_completed = g_dma.completed_count;

    if (observation_index >= EMG_TEST_FRAME_COUNT) {
        pipeline->error_flags |= EMG_PIPELINE_ERROR_COUNT;
        return;
    }

    pipeline->dma_observations[observation_index].irq_status = irq_status;
    pipeline->dma_observations[observation_index].dma_status =
        EmgDma_ReadStatus(&g_dma);
    pipeline->dma_observations[observation_index].accelerator_status =
        accelerator_status;
    pipeline->dma_observations[observation_index].rx_status = rx_status;

    if ((accelerator_status & EMG_ACCELERATOR_STATUS_BUSY_MASK) != 0U) {
        pipeline->dma_while_busy_count++;
    }
    if ((accelerator_status & EMG_ACCELERATOR_STATUS_BUSY_MASK) != 0U
        && (accelerator_status & EMG_ACCELERATOR_STATUS_FRAME_READY_MASK) != 0U) {
        pipeline->queued_frame_count++;
    }
}

static void AcceleratorInterruptHandler(void *callback_ref)
{
    EmgPipelineState *pipeline = (EmgPipelineState *)callback_ref;
    const u32 observation_index = pipeline->accelerator_completed;
    const u32 status = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_STATUS_OFFSET
    );
    const u32 result = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_RESULT_OFFSET
    );
    const u32 rx_status = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_RX_STATUS_OFFSET
    );
    const u32 error_status = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_ERROR_STATUS_OFFSET
    );
    const u32 cycle_count = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_CYCLE_COUNT_OFFSET
    );

    if ((status & EMG_ACCELERATOR_STATUS_IRQ_MASK) == 0U) {
        return;
    }

    pipeline->accelerator_irq_count++;

    if ((status & EMG_ACCELERATOR_STATUS_ERROR_MASK) != 0U
        || error_status != 0U) {
        pipeline->error_flags |= EMG_PIPELINE_ERROR_ACCELERATOR;
    }

    if (observation_index < EMG_TEST_FRAME_COUNT) {
        pipeline->inference_observations[observation_index].status = status;
        pipeline->inference_observations[observation_index].result = result;
        pipeline->inference_observations[observation_index].rx_status = rx_status;
        pipeline->inference_observations[observation_index].error_status =
            error_status;
        pipeline->inference_observations[observation_index].cycle_count =
            cycle_count;

        if (observation_index + 1U < EMG_TEST_FRAME_COUNT
            && (status & EMG_ACCELERATOR_STATUS_BUSY_MASK) != 0U) {
            pipeline->autostart_overlap_count++;
        }
        pipeline->accelerator_completed++;
    } else {
        pipeline->error_flags |= EMG_PIPELINE_ERROR_COUNT;
    }

    EmgAccelerator_WriteRegister(
        EMG_ACCELERATOR_COMMAND_OFFSET,
        EMG_ACCELERATOR_COMMAND_CLEAR_DONE_MASK
    );
}

static XStatus InitializeInterruptController(void)
{
    XScuGic_Config *config;

    config = XScuGic_LookupConfig(XPAR_SCUGIC_0_DEVICE_ID);
    if (config == NULL) {
        return XST_FAILURE;
    }
    if (XScuGic_CfgInitialize(
            &g_interrupt_controller,
            config,
            config->CpuBaseAddress
        ) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    if (EmgDma_ConnectInterrupt(
            &g_dma,
            &g_interrupt_controller,
            XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR,
            DmaEventHandler,
            &g_pipeline
        ) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XScuGic_SetPriorityTriggerType(
        &g_interrupt_controller,
        XPAR_FABRIC_EMG_ACCELERATOR_0_IRQ_INTR,
        0xA8U,
        0x1U
    );
    if (XScuGic_Connect(
            &g_interrupt_controller,
            XPAR_FABRIC_EMG_ACCELERATOR_0_IRQ_INTR,
            (Xil_InterruptHandler)AcceleratorInterruptHandler,
            &g_pipeline
        ) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XScuGic_Enable(
        &g_interrupt_controller,
        XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR
    );
    XScuGic_Enable(
        &g_interrupt_controller,
        XPAR_FABRIC_EMG_ACCELERATOR_0_IRQ_INTR
    );

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
        &g_interrupt_controller
    );
    Xil_ExceptionEnable();
    return XST_SUCCESS;
}

static XStatus StartNextDmaFrame(void)
{
    const u32 frame_index = g_pipeline.dma_started;

    if (frame_index >= EMG_TEST_FRAME_COUNT) {
        return XST_SUCCESS;
    }

    if (EmgDma_StartMm2s(
            &g_dma,
            g_emg_test_frames[frame_index],
            EMG_TEST_FRAME_BYTES
        ) != XST_SUCCESS) {
        g_pipeline.error_flags |= EMG_PIPELINE_ERROR_DMA;
        return XST_FAILURE;
    }

    g_pipeline.dma_started++;
    return XST_SUCCESS;
}

static void PrintDmaObservations(void)
{
    u32 index;

    for (index = 0U; index < g_pipeline.dma_completed; ++index) {
        const EmgDmaObservation *observation =
            (const EmgDmaObservation *)&g_pipeline.dma_observations[index];
        xil_printf(
            "DMA[%lu] irq=0x%08lx sr=0x%08lx accel=0x%08lx rx=0x%08lx\r\n",
            index,
            observation->irq_status,
            observation->dma_status,
            observation->accelerator_status,
            observation->rx_status
        );
    }
}

static void PrintInferenceObservations(void)
{
    u32 index;

    for (index = 0U; index < g_pipeline.accelerator_completed; ++index) {
        const EmgInferenceObservation *observation =
            (const EmgInferenceObservation *)&g_pipeline.inference_observations[
                index
            ];
        xil_printf(
            "ACCEL[%lu] status=0x%08lx class=%lu rx=0x%08lx error=0x%08lx cycles=%lu expected=%lu\r\n",
            index,
            observation->status,
            observation->result,
            observation->rx_status,
            observation->error_status,
            observation->cycle_count,
            (u32)g_emg_expected_classes[index]
        );
    }
}

static void ValidatePipelineResults(void)
{
    u32 index;

    if (g_pipeline.dma_completed != EMG_TEST_FRAME_COUNT
        || g_pipeline.accelerator_completed != EMG_TEST_FRAME_COUNT
        || g_dma.completed_count != EMG_TEST_FRAME_COUNT) {
        g_pipeline.error_flags |= EMG_PIPELINE_ERROR_COUNT;
    }

    for (index = 0U; index < g_pipeline.dma_completed
        && index < EMG_TEST_FRAME_COUNT; ++index) {
        if ((g_pipeline.dma_observations[index].irq_status
                & XAXIDMA_IRQ_IOC_MASK) == 0U
            || (g_pipeline.dma_observations[index].irq_status
                & XAXIDMA_IRQ_ERROR_MASK) != 0U) {
            g_pipeline.error_flags |= EMG_PIPELINE_ERROR_DMA;
        }
    }

    for (index = 0U; index < g_pipeline.accelerator_completed
        && index < EMG_TEST_FRAME_COUNT; ++index) {
        const EmgInferenceObservation *observation =
            (const EmgInferenceObservation *)&g_pipeline.inference_observations[
                index
            ];

        if (observation->error_status != 0U
            || (observation->status & EMG_ACCELERATOR_STATUS_DONE_MASK) == 0U) {
            g_pipeline.error_flags |= EMG_PIPELINE_ERROR_ACCELERATOR;
        }
        if ((observation->result & 0x7U) != g_emg_expected_classes[index]) {
            g_pipeline.error_flags |= EMG_PIPELINE_ERROR_RESULT;
        }
        if (observation->cycle_count != EMG_TEST_EXPECTED_CYCLES) {
            g_pipeline.error_flags |= EMG_PIPELINE_ERROR_CYCLE_COUNT;
        }
    }

    if (g_pipeline.autostart_overlap_count == 0U) {
        g_pipeline.error_flags |= EMG_PIPELINE_ERROR_NO_OVERLAP;
    }
    if (g_pipeline.queued_frame_count == 0U) {
        g_pipeline.error_flags |= EMG_PIPELINE_ERROR_NO_QUEUE;
    }

    g_pipeline.passed = (g_pipeline.error_flags == 0U) ? 1U : 0U;
}

static void PrintPipelineSummary(void)
{
    xil_printf("\r\n========== 10-FRAME AUTOSTART TEST ==========\r\n");
    xil_printf("DMA started              = %lu\r\n", g_pipeline.dma_started);
    xil_printf("DMA completed            = %lu\r\n", g_pipeline.dma_completed);
    xil_printf("Accelerator IRQ count    = %lu\r\n",
        g_pipeline.accelerator_irq_count);
    xil_printf("Accelerator completed    = %lu\r\n",
        g_pipeline.accelerator_completed);
    xil_printf("DMA while accelerator busy = %lu\r\n",
        g_pipeline.dma_while_busy_count);
    xil_printf("Queued-frame observations = %lu\r\n",
        g_pipeline.queued_frame_count);
    xil_printf("Autostart overlap count   = %lu\r\n",
        g_pipeline.autostart_overlap_count);
    xil_printf("Error flags              = 0x%08lx\r\n",
        g_pipeline.error_flags);
    xil_printf("RESULT                   = %s\r\n",
        g_pipeline.passed != 0U ? "PASS" : "FAIL");
    PrintDmaObservations();
    PrintInferenceObservations();
}

int main(void)
{
    u32 timeout;

    Xil_ICacheEnable();
    Xil_DCacheEnable();

    g_pipeline = (EmgPipelineState){0};

    xil_printf("\r\n==============================================\r\n");
    xil_printf("EMG accelerator 10-frame autostart test\r\n");
    xil_printf("DMA interrupt + accelerator interrupt + ping-pong\r\n");
    xil_printf("==============================================\r\n");

    if (EmgDma_Initialize(&g_dma) != XST_SUCCESS) {
        xil_printf("FAIL: DMA initialization\r\n");
        goto idle;
    }
    if (EmgAccelerator_ValidateHardware() != XST_SUCCESS) {
        xil_printf("FAIL: accelerator hardware validation\r\n");
        goto idle;
    }
    EmgAccelerator_ClearStatus();
    EmgAccelerator_WriteRegister(
        EMG_ACCELERATOR_CONFIG_OFFSET,
        EMG_ACCELERATOR_CONFIG_AUTO_START_MASK
            | EMG_ACCELERATOR_CONFIG_IRQ_ENABLE_MASK
    );

    if (InitializeInterruptController() != XST_SUCCESS) {
        xil_printf("FAIL: interrupt controller initialization\r\n");
        goto idle;
    }
    EmgDma_EnableInterrupts(&g_dma);

    for (timeout = 0U; timeout < EMG_PIPELINE_TIMEOUT_ITERATIONS; ++timeout) {
        if (g_pipeline.error_flags != 0U) {
            break;
        }

        if (g_dma.active == 0U
            && g_pipeline.dma_started < EMG_TEST_FRAME_COUNT) {
            if (StartNextDmaFrame() != XST_SUCCESS) {
                break;
            }
        }

        if (g_pipeline.dma_completed == EMG_TEST_FRAME_COUNT
            && g_pipeline.accelerator_completed == EMG_TEST_FRAME_COUNT
            && g_dma.active == 0U) {
            break;
        }
    }

    if (timeout == EMG_PIPELINE_TIMEOUT_ITERATIONS) {
        g_pipeline.error_flags |= EMG_PIPELINE_ERROR_COUNT;
        xil_printf("ERROR: 10-frame pipeline timeout\r\n");
    }

    ValidatePipelineResults();
    g_pipeline.finished = 1U;
    PrintPipelineSummary();

    EmgDma_DisableInterrupts(&g_dma);
    EmgAccelerator_WriteRegister(EMG_ACCELERATOR_CONFIG_OFFSET, 0U);

idle:
    while (1) {
        __asm__ volatile("wfi");
    }
}
