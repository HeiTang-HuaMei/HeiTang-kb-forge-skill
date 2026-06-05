def contract_status(files_present: bool) -> str:
    return "pass" if files_present else "warning"
