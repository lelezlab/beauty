import Foundation

public enum EvalRunner {
    public static func run(specURL: URL) {
        // Minimal placeholder: create empty CSV report
        let out = "id,consistency,boundary,hit\n"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("eval_report.csv")
        try? out.data(using: .utf8)?.write(to: url)
        print("Eval report written:", url.path)
    }
}


