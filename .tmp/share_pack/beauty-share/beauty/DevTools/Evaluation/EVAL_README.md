# Evaluation Harness

1. Put samples under `EvalSamples/` and describe them in `DevTools/Evaluation/EvalDatasetSpec.json`.
2. From Developer/Debug page (to be wired) or a debug button, call `EvalRunner.run(specURL:)`.
3. The tool generates `Documents/eval_report.csv` with columns: id, consistency, boundary, hit.
