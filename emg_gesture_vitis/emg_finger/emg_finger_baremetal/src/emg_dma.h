#ifndef EMG_FINGER_APP_DMA_H
#define EMG_FINGER_APP_DMA_H

#include "xaxidma.h"
#include "xil_types.h"
#include "xscugic.h"
#include "xstatus.h"

typedef void (*EmgDmaEventHandler)(void *callback_ref, u32 irq_status);

typedef struct {
    XAxiDma instance;
    volatile u32 active;
    volatile u32 completed_count;
    volatile u32 error_status;
    EmgDmaEventHandler event_handler;
    void *callback_ref;
} EmgDma;

XStatus EmgDma_Initialize(EmgDma *dma);
XStatus EmgDma_ConnectInterrupt(
    EmgDma *dma,
    XScuGic *interrupt_controller,
    u32 interrupt_id,
    EmgDmaEventHandler event_handler,
    void *callback_ref
);
void EmgDma_EnableInterrupts(EmgDma *dma);
void EmgDma_DisableInterrupts(EmgDma *dma);
XStatus EmgDma_StartMm2s(EmgDma *dma, const void *buffer, u32 byte_count);
u32 EmgDma_ReadStatus(const EmgDma *dma);

#endif
