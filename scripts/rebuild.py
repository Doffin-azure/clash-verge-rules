import argparse
from concurrent.futures import Future
from http.client import HTTPException, HTTPResponse, NO_CONTENT
import json
import msvcrt
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory
from threading import Thread

from ruamel.yaml import YAML


def read_config(yaml, path):
    with path.open(encoding="utf-8-sig") as file:
        config = yaml.load(file)
    if not isinstance(config, dict):
        raise ValueError(f"{path}: expected a YAML mapping")
    return config


def rule_list(config, key):
    rules = config.get(key, [])
    if not isinstance(rules, list) or any(not isinstance(rule, str) for rule in rules):
        raise ValueError(f"{key}: expected a list of rule strings")
    return rules


class PipeReader:
    def __init__(self, stream):
        self.stream = stream

    def makefile(self, mode):
        return self.stream


def reload_config(pipe_name, runtime_path):
    body = json.dumps({"path": str(runtime_path)}).encode("utf-8")
    headers = (
        "PUT /configs?force=true HTTP/1.1\r\n"
        "Host: localhost\r\n"
        "Connection: close\r\n"
        "Content-Type: application/json\r\n"
        f"Content-Length: {len(body)}\r\n\r\n"
    )

    def request():
        try:
            with open(rf"\\.\pipe\{pipe_name}", "r+b", buffering=0) as stream:
                message = headers.encode("ascii") + body
                if stream.write(message) != len(message):
                    raise OSError("Incomplete write to the Mihomo named pipe")
                with HTTPResponse(PipeReader(stream), method="PUT") as response:
                    response.begin()
                    if response.status != NO_CONTENT:
                        raise RuntimeError(f"Mihomo returned HTTP {response.status} {response.reason}")
        except (OSError, HTTPException, RuntimeError) as error:
            outcome.set_exception(error)
        else:
            outcome.set_result(None)

    outcome = Future()
    Thread(target=request, daemon=True).start()
    outcome.result(timeout=10)


def rebuild(args, runtime):
    backup = runtime.with_suffix(".yaml.rebuildbak")
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.indent(mapping=2, sequence=4, offset=2)
    config = read_config(yaml, runtime)
    subscription = read_config(yaml, args.subscription)
    if "rules" not in subscription:
        raise ValueError(f"{args.subscription}: missing rules")
    template = read_config(yaml, args.template)

    deletions = set(rule_list(template, "delete"))
    base_rules = [rule for rule in rule_list(subscription, "rules") if rule not in deletions]
    merged = list(dict.fromkeys(rule_list(template, "prepend") + base_rules + rule_list(template, "append")))
    if not merged:
        raise ValueError("The rebuilt rules list is empty")
    config["rules"] = merged

    with TemporaryDirectory(prefix="rebuild-", dir=runtime.parent) as folder:
        folder = Path(folder)
        candidate = folder / runtime.name
        original = folder / backup.name
        with candidate.open("w", encoding="utf-8") as file:
            yaml.dump(config, file)
        if args.mihomo:
            subprocess.run(
                [str(args.mihomo.resolve()), "-t", "-f", str(candidate), "-d", str(runtime.parent)],
                check=True,
                timeout=30,
            )
        shutil.copy2(runtime, original)
        original.replace(backup)
        candidate.replace(runtime)
        try:
            reload_config(args.pipe_name, runtime)
        except (OSError, HTTPException, RuntimeError) as error:
            shutil.copy2(backup, original)
            original.replace(runtime)
            raise RuntimeError("Mihomo reload failed and the original runtime file was restored") from error
    print(f"Reloaded {len(merged)} rules. Backup: {backup}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--subscription", required=True, type=Path)
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--verge-dir", required=True, type=Path)
    parser.add_argument("--pipe-name", required=True)
    parser.add_argument("--mihomo", type=Path)
    args = parser.parse_args()

    runtime = args.verge_dir.resolve() / "clash-verge.yaml"
    with runtime.with_suffix(".yaml.rebuild.lock").open("a+b") as lock:
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        rebuild(args, runtime)


if __name__ == "__main__":
    main()
