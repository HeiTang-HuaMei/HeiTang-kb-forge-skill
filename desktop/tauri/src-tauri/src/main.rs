use std::process::Command;

#[tauri::command]
fn run_kb_forge(workflow: String, input_path: String, output_path: String, domain: String, mode: String) -> Result<String, String> {
    let mut args = match workflow.as_str() {
        "build" | "batch" => vec![
            workflow,
            "--input".to_string(),
            input_path,
            "--output".to_string(),
            output_path,
            "--domain".to_string(),
            domain,
            "--mode".to_string(),
            mode,
        ],
        "pipeline" => vec!["pipeline".to_string(), "--config".to_string(), input_path],
        _ => return Err("Unsupported workflow".to_string()),
    };

    let output = Command::new("heitang-kb-forge")
        .args(args.drain(..))
        .output()
        .map_err(|error| format!("Failed to start heitang-kb-forge: {error}"))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![run_kb_forge])
        .run(tauri::generate_context!())
        .expect("error while running HeiTang KB Forge Desktop");
}
