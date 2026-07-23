#include "emg_accelerator.h"

#include "xil_io.h"
#include "xil_printf.h"
#include "xparameters.h"

#define EMG_ACCELERATOR_BASE_ADDRESS \
    ((UINTPTR)XPAR_EMG_ACCELERATOR_0_S00_AXI_BASEADDR)

u32 EmgAccelerator_ReadRegister(u32 offset)
{
    return Xil_In32(EMG_ACCELERATOR_BASE_ADDRESS + offset);
}

void EmgAccelerator_WriteRegister(u32 offset, u32 value)
{
    Xil_Out32(EMG_ACCELERATOR_BASE_ADDRESS + offset, value);
}

void EmgAccelerator_ClearStatus(void)
{
    EmgAccelerator_WriteRegister(
        EMG_ACCELERATOR_COMMAND_OFFSET,
        EMG_ACCELERATOR_COMMAND_CLEAR_DONE_MASK
            | EMG_ACCELERATOR_COMMAND_CLEAR_ERRORS_MASK
    );
}

XStatus EmgAccelerator_ValidateHardware(void)
{
    const u32 version = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_VERSION_OFFSET
    );
    const u32 frame_info = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_FRAME_INFO_OFFSET
    );

    xil_printf("Accelerator VERSION    = 0x%08lx\r\n", version);
    xil_printf("Accelerator FRAME_INFO = 0x%08lx\r\n", frame_info);

    if (version != EMG_ACCELERATOR_EXPECTED_VERSION) {
        xil_printf(
            "ERROR: expected VERSION 0x%08lx\r\n",
            (u32)EMG_ACCELERATOR_EXPECTED_VERSION
        );
        return XST_FAILURE;
    }

    if (frame_info != EMG_ACCELERATOR_EXPECTED_FRAME_INFO) {
        xil_printf(
            "ERROR: expected FRAME_INFO 0x%08lx\r\n",
            (u32)EMG_ACCELERATOR_EXPECTED_FRAME_INFO
        );
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}

XStatus EmgAccelerator_WaitForStatus(
    u32 mask,
    u32 expected,
    u32 timeout_iterations,
    u32 *last_status
)
{
    u32 iteration;
    u32 status = 0U;

    for (iteration = 0U; iteration < timeout_iterations; ++iteration) {
        status = EmgAccelerator_ReadRegister(
            EMG_ACCELERATOR_STATUS_OFFSET
        );
        if ((status & mask) == expected) {
            if (last_status != NULL) {
                *last_status = status;
            }
            return XST_SUCCESS;
        }
    }

    if (last_status != NULL) {
        *last_status = status;
    }
    return XST_FAILURE;
}

void EmgAccelerator_PrintSnapshot(void)
{
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
    const u32 config = EmgAccelerator_ReadRegister(
        EMG_ACCELERATOR_CONFIG_OFFSET
    );

    xil_printf("STATUS       = 0x%08lx\r\n", status);
    xil_printf("RESULT       = 0x%08lx\r\n", result);
    xil_printf("RX_STATUS    = 0x%08lx\r\n", rx_status);
    xil_printf("ERROR_STATUS = 0x%08lx\r\n", error_status);
    xil_printf("CYCLE_COUNT  = %lu\r\n", cycle_count);
    xil_printf("CONFIG       = 0x%08lx\r\n", config);
}
