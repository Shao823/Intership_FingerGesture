
#ifndef EMG_ACCELERATOR_H
#define EMG_ACCELERATOR_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

#define EMG_ACCELERATOR_S00_AXI_SLV_REG0_OFFSET 0
#define EMG_ACCELERATOR_S00_AXI_SLV_REG1_OFFSET 4
#define EMG_ACCELERATOR_S00_AXI_SLV_REG2_OFFSET 8
#define EMG_ACCELERATOR_S00_AXI_SLV_REG3_OFFSET 12
#define EMG_ACCELERATOR_S00_AXI_SLV_REG4_OFFSET 16
#define EMG_ACCELERATOR_S00_AXI_SLV_REG5_OFFSET 20
#define EMG_ACCELERATOR_S00_AXI_SLV_REG6_OFFSET 24
#define EMG_ACCELERATOR_S00_AXI_SLV_REG7_OFFSET 28

#define EMG_ACCELERATOR_CONTROL_OFFSET       EMG_ACCELERATOR_S00_AXI_SLV_REG0_OFFSET
#define EMG_ACCELERATOR_STATUS_OFFSET        EMG_ACCELERATOR_S00_AXI_SLV_REG1_OFFSET
#define EMG_ACCELERATOR_RESULT_OFFSET        EMG_ACCELERATOR_S00_AXI_SLV_REG2_OFFSET
#define EMG_ACCELERATOR_FRAME_INFO_OFFSET    EMG_ACCELERATOR_S00_AXI_SLV_REG3_OFFSET
#define EMG_ACCELERATOR_RX_STATUS_OFFSET     EMG_ACCELERATOR_S00_AXI_SLV_REG4_OFFSET
#define EMG_ACCELERATOR_ERROR_STATUS_OFFSET  EMG_ACCELERATOR_S00_AXI_SLV_REG5_OFFSET
#define EMG_ACCELERATOR_CYCLE_COUNT_OFFSET   EMG_ACCELERATOR_S00_AXI_SLV_REG6_OFFSET
#define EMG_ACCELERATOR_VERSION_OFFSET       EMG_ACCELERATOR_S00_AXI_SLV_REG7_OFFSET

#define EMG_ACCELERATOR_CONTROL_START_MASK         0x00000001U
#define EMG_ACCELERATOR_CONTROL_AUTO_START_MASK    0x00000002U
#define EMG_ACCELERATOR_CONTROL_CLEAR_DONE_MASK    0x00000004U
#define EMG_ACCELERATOR_CONTROL_CLEAR_ERRORS_MASK  0x00000008U
#define EMG_ACCELERATOR_CONTROL_IRQ_ENABLE_MASK    0x00000010U

#define EMG_ACCELERATOR_STATUS_BUSY_MASK             0x00000001U
#define EMG_ACCELERATOR_STATUS_DONE_MASK             0x00000002U
#define EMG_ACCELERATOR_STATUS_FRAME_READY_MASK      0x00000004U
#define EMG_ACCELERATOR_STATUS_RX_ACTIVE_MASK        0x00000008U
#define EMG_ACCELERATOR_STATUS_ACT_WRITE_READY_MASK  0x00000010U
#define EMG_ACCELERATOR_STATUS_CLASS_VALID_MASK      0x00000020U
#define EMG_ACCELERATOR_STATUS_IRQ_MASK              0x00000040U
#define EMG_ACCELERATOR_STATUS_START_NO_FRAME_MASK   0x00000080U
#define EMG_ACCELERATOR_STATUS_START_BUSY_MASK       0x00000100U
#define EMG_ACCELERATOR_STATUS_ERROR_MASK            0x00000200U

#define EMG_ACCELERATOR_ERROR_EARLY_TLAST_MASK      0x00000001U
#define EMG_ACCELERATOR_ERROR_MISSING_TLAST_MASK    0x00000002U
#define EMG_ACCELERATOR_ERROR_BAD_KEEP_MASK         0x00000004U
#define EMG_ACCELERATOR_ERROR_DROPPED_FRAME_MASK    0x00000008U
#define EMG_ACCELERATOR_ERROR_START_NO_FRAME_MASK   0x00000010U
#define EMG_ACCELERATOR_ERROR_START_BUSY_MASK       0x00000020U


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a EMG_ACCELERATOR register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the EMG_ACCELERATORdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void EMG_ACCELERATOR_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define EMG_ACCELERATOR_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a EMG_ACCELERATOR register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the EMG_ACCELERATOR device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 EMG_ACCELERATOR_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define EMG_ACCELERATOR_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

/************************** Function Prototypes ****************************/
/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the EMG_ACCELERATOR instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus EMG_ACCELERATOR_Reg_SelfTest(void * baseaddr_p);

#endif // EMG_ACCELERATOR_H
