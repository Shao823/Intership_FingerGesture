# LightCNN1D HLS 参数导出

- checkpoint: `/mnt/d/intership/emg_gesture_repro/checkpoint_best.pt`
- epoch: `34`
- best_val_macro_f1: `0.9036889783823897`
- class_labels: `[1, 2, 3, 4, 5]`
- 参数总数: `20357` float32
- HLS 头文件: `/mnt/d/intership/emg_gesture_hls/src/LightCNN1D_Params.h`
- 人工检查 CSV: `/mnt/d/intership/工程实现流程建议/LightCNN1D参数导出/LightCNN1D_params_flat.csv`

参数顺序严格对应 `LightCNN1D_Accelerator.cpp` 中的 `PARAM_*` offset。
