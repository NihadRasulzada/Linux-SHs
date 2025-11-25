#!/usr/bin/env python3
"""
ASP.NET Core / Blazor Layihə Analiz Skripti v4
Ollama + Qwen2.5-Coder ilə işləyir
Kod keyfiyyəti, runtime/compile error riskləri, performans və optimizasiya təkliflərini analiz edir.
Stream rejimi + fayl summary ilə böyük layihələr üçün optimallaşdırılıb.
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime
import glob
from tempfile import NamedTemporaryFile

# --- Rənglər ---
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(60)}{Colors.END}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.END}\n")

def print_info(text): print(f"{Colors.CYAN}ℹ️  {text}{Colors.END}")
def print_success(text): print(f"{Colors.GREEN}✅ {text}{Colors.END}")
def print_error(text): print(f"{Colors.RED}❌ {text}{Colors.END}")
def print_warning(text): print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")

# --- Ollama yoxlama ---
def check_ollama():
    try:
        subprocess.run(['ollama', 'list'], capture_output=True, text=True)
        return True
    except FileNotFoundError:
        return False

def check_model(model_name="qwen2.5-coder:32b"):
    try:
        result = subprocess.run(['ollama', 'list'], capture_output=True, text=True)
        return model_name in result.stdout
    except:
        return False

# --- Fayl scanning ---
def scan_project_files(project_path, extensions):
    files = []
    for ext in extensions:
        pattern = os.path.join(project_path, '**', f'*{ext}')
        files.extend(glob.glob(pattern, recursive=True))
    exclude_dirs = {'obj', 'bin', 'node_modules', '.git', '.vs', 'wwwroot/lib'}
    filtered = [f for f in files if not any(ex in f for ex in exclude_dirs)]
    return filtered

def prepare_file_summary(file_path, max_preview=300):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            preview = ''.join(lines[:10])[:max_preview]
            return {
                "path": file_path,
                "extension": os.path.splitext(file_path)[1],
                "lines_count": len(lines),
                "preview": preview.replace("\n", "\\n")
            }
    except:
        return {
            "path": file_path,
            "extension": os.path.splitext(file_path)[1],
            "lines_count": 0,
            "preview": "[oxunmadı]"
        }

# --- Runtime və compile analizi ---
def runtime_and_compile_analysis(project_path):
    print_info("Runtime və compile analizi aparılır...")
    results = {"build": "", "runtime_issues": []}
    try:
        build_result = subprocess.run(
            ["dotnet", "build", project_path, "-clp:ErrorsOnly"],
            capture_output=True,
            text=True
        )
        if build_result.returncode != 0:
            results["build"] = build_result.stderr.strip()
        else:
            results["build"] = "✅ Build uğurla keçdi!"

        test_dirs = glob.glob(os.path.join(project_path, "**", "*.Tests.csproj"), recursive=True)
        if test_dirs:
            test_result = subprocess.run(["dotnet", "test", "--no-build"], capture_output=True, text=True)
            if test_result.returncode != 0:
                results["runtime_issues"].append("❌ Unit testlərdə uğursuz nəticələr var.")
    except Exception as e:
        results["runtime_issues"].append(str(e))

    return results

# --- AI Analizi (Stream) ---
def analyze_with_ollama(project_info, model_name="qwen2.5-coder:32b"):
    print_info(f"AI analizi başlayır ({model_name})...")
    print_warning("Bu bir neçə dəqiqə çəkə bilər...")

    prompt = f"""
Mənə ASP.NET Core / Blazor layihəsinin fayl summary-ləri verildi.
Zəhmət olmasa dərin analiz et və tam JSON cavab ver:

{{
  "project_summary": "...",
  "technology_stack": ["..."],
  "architecture_analysis": "...",
  "code_quality": {{
      "score": 1-10,
      "strengths": ["..."],
      "weaknesses": ["..."]
  }},
  "potential_runtime_errors": ["kodda ola biləcək runtime exception-lar və səbəbləri"],
  "compile_time_warnings": ["potensial compiler warning və düzəliş təklifi"],
  "redundant_code": ["lazımsız və ya təkrarlanan kod hissələri"],
  "performance_bottlenecks": ["performansı azaldan yerlər və səbəbi"],
  "improvement_suggestions": ["ümumi yaxşılaşdırma təklifləri"],
  "file_statistics": {{
      "total_files": sayı,
      "code_lines": təxmini_sətir_sayı
  }}
}}

Layihə məlumatları:
{json.dumps(project_info, ensure_ascii=False, indent=2)}

Yalnız JSON cavab ver!
"""

    try:
        process = subprocess.Popen(
            ['ollama', 'run', model_name],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )

        process.stdin.write(prompt)
        process.stdin.close()

        print_info("Model işləyir... nəticə axınla gəlir...")
        output_lines = []

        for line in process.stdout:
            line = line.strip()
            if line:
                print(f"{Colors.BLUE}{line}{Colors.END}")
                output_lines.append(line)

        process.wait(timeout=1800)  # 30 dəqiqə

        response = "".join(output_lines)
        json_start = response.find('{')
        json_end = response.rfind('}') + 1

        if json_start != -1 and json_end > json_start:
            return json.loads(response[json_start:json_end])
        else:
            print_warning("Tam JSON qaytarılmadı, xam nəticə saxlanacaq.")
            return {"raw_response": response}

    except subprocess.TimeoutExpired:
        print_error("AI analiz çox uzun çəkdi və dayandırıldı.")
        return {"error": "timeout", "raw_response": "".join(output_lines)}
    except Exception as e:
        print_error(f"AI analiz xətası: {e}")
        return None

# --- Əsas funksiya ---
def main():
    print_header("ASP.NET Core / Blazor Layihə Analiz Aləti v4")

    if not check_ollama():
        print_error("Ollama quraşdırılmayıb! → https://ollama.ai")
        sys.exit(1)

    model = "qwen2.5-coder:32b"
    if not check_model(model):
        print_info("Model yüklənir...")
        subprocess.run(["ollama", "pull", model])

    project_path = input(f"{Colors.CYAN}Layihə qovluğunun tam yolunu daxil edin: {Colors.END}").strip()
    if not os.path.isdir(project_path):
        print_error("Düzgün qovluq deyil!")
        sys.exit(1)

    print_success(f"Layihə: {os.path.basename(project_path)}")

    runtime_info = runtime_and_compile_analysis(project_path)

    exts = ['.cs', '.razor', '.cshtml', '.json', '.csproj']
    files = scan_project_files(project_path, exts)

    project_info = {
        "project_name": os.path.basename(project_path),
        "files": [prepare_file_summary(f) for f in files],
        "runtime_compile_info": runtime_info
    }

    analysis = analyze_with_ollama(project_info, model)
    if not analysis:
        print_error("Analiz uğursuz oldu.")
        sys.exit(1)

    report_dir = Path.home() / "project_reports"
    report_dir.mkdir(exist_ok=True)
    output = report_dir / f"report_{os.path.basename(project_path)}_{datetime.now().strftime('%Y%m%d_%H%M')}.html"

    tmp = NamedTemporaryFile(delete=False, suffix=".json", mode='w', encoding='utf-8')
    json.dump(analysis, tmp, ensure_ascii=False, indent=2)
    tmp.close()

    print_success(f"Analiz tamamlandı! Report: {output}")
    print_info(f"Xam nəticə: {tmp.name}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print_warning("İstifadəçi tərəfindən dayandırıldı.")
        sys.exit(0)
