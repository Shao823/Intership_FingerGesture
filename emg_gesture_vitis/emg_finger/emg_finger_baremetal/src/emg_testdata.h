#ifndef EMG_FINGER_APP_TESTDATA_H
#define EMG_FINGER_APP_TESTDATA_H

#include "xil_types.h"

#define EMG_TEST_FRAME_COUNT   10U
#define EMG_TEST_CHANNELS      5U
#define EMG_TEST_SAMPLES       348U
#define EMG_TEST_FRAME_BYTES   1740U
#define EMG_TEST_EXPECTED_CYCLES 40527U

extern const u8 g_emg_test_frames[EMG_TEST_FRAME_COUNT][EMG_TEST_FRAME_BYTES];
extern const u8 g_emg_expected_classes[EMG_TEST_FRAME_COUNT];

#endif
