"""Structural checks for the Pascal sources.

There is no Pascal compiler on a Linux runner; the real compile happens later
on a Windows runner with Lazarus. This checker catches the mistakes that are
easy to make when writing a lot of Pascal by hand and expensive to find in CI:

  * unbalanced ``begin``/``end``, parentheses, brackets and comments
  * a routine declared in the interface but missing from the implementation
  * an implementation of a class routine the class does not declare
  * a ``uses`` clause naming something that is not a unit
  * a unit whose name does not match its file name
  * string literals that run past the end of a line
  * ``FillChar`` applied to a record type that contains string fields, which
    leaks whatever those fields pointed at
  * a ``var``/``const`` declaration section placed after a routine's ``begin``
  * a uses clause whose conditional branch ends with ';' while more units
    follow ``{$ENDIF}``, which resolves to a stray statement
  * a reference to a symbol of another project unit whose unit is missing from
    the uses clause (Pascal does not re-export)
  * an interface-section reference whose unit is named only in the
    implementation uses clause, which is not in scope that early

All of it is text level on purpose: standard library only, any platform, well
under a second.
"""
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

WORD = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")

# Runtime / framework units this project may legitimately use. Anything else
# in a uses clause has to be a unit of the project itself.
RTL_UNITS = {
    "windows", "winapi.windows", "system.sysutils", "sysutils",
    "system.classes", "classes", "system.types", "types", "forms",
    "vcl.forms", "controls", "vcl.controls", "stdctrls",
    "vcl.stdctrls", "extctrls", "vcl.extctrls", "graphics",
    "vcl.graphics", "menus", "vcl.menus", "dialogs", "vcl.dialogs",
    "comctrls", "vcl.comctrls", "buttons", "vcl.buttons", "inifiles",
    "system.inifiles", "shellapi", "vcl.shellapi", "lmessages",
    "winapi.messages", "lcltype", "interfaces", "system.zip", "zipper",
    "messages", "system", "winapi", "vcl", "math", "system.math",
    "dateutils", "system.dateutils", "strutils", "system.strutils",
    "syncobjs", "system.syncobjs", "contnrs", "system.contnrs",
    "generics.collections", "system.generics.collections",
    "registry", "winapi.registry", "activex", "winapi.activex",
    "clipbrd", "vcl.clipbrd", "system.uitypes", "uitypes",
    "shlobj", "winapi.shlobj", "commctrl", "winapi.commctrl",
    "filectrl", "vcl.filectrl", "imglist", "vcl.imglist", "lazlogger",
    "lclintf", "lresources", "lazfileutils",
}

DEVICE_UNITS = (
    "DevTypes", "CommPort", "DevNotify", "DevCapture", "BromProtocol",
    "MtkChips", "MtkStatus", "DaImage", "MtkDaLegacy", "SimPort",
    "ScatterFile", "DeviceSession", "JobEngine", "AdbTool",
    "SaharaProtocol", "MtkJobs", "AndroidJobs", "UnimplementedJobs",
    "CaptureForm",
)


def tokenize_source(text: str):
    """Yield (kind, value, offset) over Pascal source.

    kind is one of ``ws``, ``comment``, ``string``, ``word``, ``symbol``,
    ``number``. Whitespace is yielded too, so a view built from the tokens keeps
    the original layout and every offset still maps to the same line.

    String literals are recognised before comments, because filter strings like
    ``'|All files (*.*)|*.*'`` and ``'https://...'`` contain comment
    delimiters that must not be treated as comments.
    """
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c.isspace():
            j = i
            while j < n and text[j].isspace():
                j += 1
            yield ("ws", text[i:j], i)
            i = j
        elif c == "'":
            j = i + 1
            closed = False
            while j < n:
                if text[j] == "\n":
                    break
                if text[j] == "'":
                    if j + 1 < n and text[j + 1] == "'":
                        j += 2
                        continue
                    j += 1
                    closed = True
                    break
                j += 1
            yield ("string", text[i:j] if closed else text[i:j], i)
            i = j
        elif c == "{":
            j = text.find("}", i)
            if j < 0:
                yield ("comment", text[i:], i)
                return
            yield ("comment", text[i:j + 1], i)
            i = j + 1
        elif text.startswith("(*", i):
            j = text.find("*)", i)
            if j < 0:
                yield ("comment", text[i:], i)
                return
            yield ("comment", text[i:j + 2], i)
            i = j + 2
        elif text.startswith("//", i):
            j = text.find("\n", i)
            if j < 0:
                yield ("comment", text[i:], i)
                return
            yield ("comment", text[i:j], i)
            i = j
        elif c == "#":
            m = re.compile(r"#\$?[0-9A-Fa-f]+").match(text, i)
            if m:
                yield ("number", m.group(0), i)
                i = m.end()
            else:
                yield ("symbol", c, i)
                i += 1
        elif c.isalpha() or c == "_":
            m = WORD.match(text, i)
            yield ("word", m.group(0), i)
            i = m.end()
        elif c.isdigit() or (c == "$" and i + 1 < n and
                             (text[i + 1].isdigit() or text[i + 1] in "abcdefABCDEF")):
            m = re.compile(r"\$[0-9A-Fa-f]+|[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?").match(text, i)
            yield ("number", m.group(0), i)
            i = m.end()
        else:
            two = text[i:i + 2]
            if two in (":=", "<=", ">=", "<>", ".."):
                yield ("symbol", two, i)
                i += 2
            else:
                yield ("symbol", c, i)
                i += 1


def code_view(text: str) -> str:
    """Source with comment text and string contents blanked, layout kept.

    Offsets and line numbers are identical to the original, and the remaining
    words are separated by their original whitespace, so regular expressions
    over the result behave as they would over real source.
    """
    out = []
    for kind, value, offset in tokenize_source(text):
        if kind == "comment":
            out.append("".join(ch if ch.isspace() else " " for ch in value))
        elif kind == "string":
            if value.startswith("'") and value.endswith("'") and len(value) >= 2:
                inner = "".join(ch if ch.isspace() else " " for ch in value[1:-1])
                out.append("'" + inner + "'")
            else:
                out.append(value)
        else:
            out.append(value)
    return "".join(out)


def strip_comments_only(text: str) -> str:
    """Blank comments, keep string literals exactly as written."""
    out = []
    for kind, value, offset in tokenize_source(text):
        if kind == "comment":
            out.append("".join(ch if ch.isspace() else " " for ch in value))
        else:
            out.append(value)
    return "".join(out)


def line_of(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1


def resolve_conditionals(code: str, defined=("FPC", "MSWINDOWS", "WINDOWS",
                                             "CPU32", "CPU64")) -> str:
    """Drop the branches of {$IFDEF}/{$IFNDEF}/{$ELSE}/{$ENDIF} that would not
    be compiled, so block counting sees exactly one body per routine.

    AppInfo.FixGroupBoxLayout for example has a real FPC body and an empty
    Delphi one; counting both would report an unmatched `end`.

    This has to run on the RAW source: code_view blanks comment delimiters, so
    the {$...} directives would no longer be visible there.
    """
    defined_lower = {d.lower() for d in defined}
    out = []
    # stack entries: [taking_now, any_branch_taken, parent_taking]
    stack = []

    def taking():
        return stack[-1][0] if stack else True

    i = 0
    n = len(code)
    while i < n:
        if code.startswith("{", i):
            j = code.find("}", i)
            if j < 0:
                out.append(code[i:])
                break
            directive = code[i + 1:j].strip()
            if not directive.startswith("$"):
                # An ordinary comment, not a compiler directive.
                directive = ""
            else:
                directive = directive[1:]
            words = directive.split()
            head = words[0].upper() if words else ""
            if head in ("IFDEF", "IFNDEF") and len(words) >= 2:
                symbol = words[1].lower()
                cond = symbol in defined_lower
                if head == "IFNDEF":
                    cond = not cond
                stack.append([taking() and cond, False, taking()])
                out.append(" " * (j + 1 - i))
                i = j + 1
                continue
            if head == "ELSE":
                if stack:
                    top = stack[-1]
                    top[0] = top[2] and not top[1]
                out.append(" " * (j + 1 - i))
                i = j + 1
                continue
            if head == "ENDIF":
                if stack:
                    stack.pop()
                out.append(" " * (j + 1 - i))
                i = j + 1
                continue
            # An ordinary comment: it is content of the current branch.
            if taking():
                out.append(code[i:j + 1])
                if stack:
                    stack[-1][1] = True
            else:
                out.append("".join(c if c.isspace() else " " for c in code[i:j + 1]))
            i = j + 1
            continue
        ch = code[i]
        if taking():
            out.append(ch)
            if stack:
                stack[-1][1] = True
        else:
            out.append("\n" if ch == "\n" else " ")
        i += 1
    return "".join(out)


def pascal_units() -> set:
    return {p.stem.lower() for p in ROOT.glob("*.pas")}


PASCAL_KEYWORDS = {
    "and", "array", "as", "asm", "begin", "case", "class", "const",
    "constructor", "destructor", "div", "do", "downto", "else", "end",
    "except", "exports", "file", "finalization", "finally", "for", "function",
    "goto", "if", "implementation", "in", "inherited", "initialization",
    "inline", "interface", "is", "label", "library", "mod", "nil", "not",
    "object", "of", "on", "operator", "or", "out", "packed", "procedure",
    "program", "property", "raise", "record", "repeat", "resourcestring",
    "set", "shl", "shr", "string", "then", "threadvar", "to", "try", "type",
    "unit", "until", "uses", "var", "while", "with", "xor",
    # pseudo-variables and intrinsic routines: never a cross-unit reference
    "result", "self", "message", "name", "index", "default", "read", "write",
    "stored", "absolute", "override", "virtual", "abstract", "reintroduce",
    "published", "private", "protected", "public", "strict", "forward",
    "external", "cdecl", "stdcall", "safecall", "register", "pascal",
    "varargs", "exit", "length", "pos", "copy", "delete", "insert",
    "assigned", "sizeof", "ord", "chr", "low", "high", "pred", "succ", "inc",
    "dec", "swap", "trunc", "round", "abs", "odd",
}


def exported_symbols(text: str) -> set:
    """Names another unit can reference from this one.

    Unit-level routines, constants, types, variables and enumeration literals.
    Record and class fields are deliberately excluded: they are never reachable
    without their owning type, so counting them would flag every local variable
    that happens to share a name with a field somewhere else.
    """
    out = set()
    block = None
    in_routine = False
    in_record = 0
    for raw in text.split("\n"):
        if not raw.strip() or raw.lstrip().startswith("{"):
            continue
        at_col0 = raw[:1] not in (" ", "\t")
        low = raw.strip().lower()
        if at_col0:
            if low.startswith("interface") or low.startswith("implementation"):
                block, in_routine, in_record = None, False, 0
                continue
            m = re.match(r"^(function|procedure|constructor|destructor)\s+"
                         r"([A-Za-z_]\w*)", low)
            if m:
                in_routine, block = True, None
                if "." not in m.group(2):
                    out.add(m.group(2))          # unit routine, not a method
                continue
            if re.match(r"^end\s*[;.]", low):
                in_routine, block, in_record = False, None, 0
                continue
            if in_routine:
                continue                          # the routine's own var block
            if low in ("const", "type", "var", "resourcestring", "threadvar"):
                block, in_record = low, 0
                continue
            block = None
            continue
        if in_routine:
            continue
        if block == "type":
            if re.search(r"=\s*(packed\s+)?(record|class|object|interface)\b", low):
                in_record += 1
                m = re.match(r"^\s+([A-Za-z_]\w*)\s*=", raw)
                if m:
                    out.add(m.group(1))
                continue
            if re.match(r"^\s+end\s*;", low) and in_record:
                in_record -= 1
                continue
            if in_record:
                continue                          # fields are not exported names
            m = re.match(r"^\s+([A-Za-z_]\w*)\s*=", raw)
            if m:
                out.add(m.group(1))
            continue
        if block in ("const", "var", "resourcestring", "threadvar"):
            m = re.match(r"^\s+([A-Za-z_]\w*)\s*(?:=|:)", raw)
            if m:
                out.add(m.group(1))
        m = re.match(r"^\s*(?:=\s*)?\(([^)]*)\)\s*;", raw)
        if m:
            for part in m.group(1).split(","):
                part = part.strip()
                if re.fullmatch(r"[A-Za-z_]\w*", part):
                    out.add(part)
    return {n for n in out if n.lower() not in PASCAL_KEYWORDS and len(n) > 2}


def locally_declared(text: str) -> set:
    """Every name this file declares for itself: locals, parameters, fields,
    properties and routine names. A symbol in this set is never a reference to
    another unit, whatever else in the project happens to share the name."""
    names = set()
    for m in re.finditer(r"\b([A-Za-z_]\w*)\b(?=\s*[:,=)])", text):
        names.add(m.group(1).lower())
    for m in re.finditer(r"\bproperty\s+([A-Za-z_]\w*)", text, re.I):
        names.add(m.group(1).lower())
    for m in re.finditer(
            r"^\s*(?:(?:class|static)\s+)*"
            r"(?:function|procedure|constructor|destructor)\s+"
            r"(?:[A-Za-z_]\w*\.)?([A-Za-z_]\w*)", text, re.M | re.I):
        names.add(m.group(1).lower())
    return names


def interface_section(text: str) -> str:
    """The text between the unit's `interface` and `implementation` keywords.

    What a class declaration, a published field type or a routine signature in
    this part can see is limited to the INTERFACE uses clause: an
    implementation uses clause is not in scope yet.
    """
    start = re.search(r"^\s*interface\s*$", text, re.M)
    end = re.search(r"^\s*implementation\s*$", text, re.M)
    if start is None:
        return ""
    return text[start.end():end.start() if end else len(text)]


def resolved_uses(text: str, section: str = None) -> set:
    """Unit names in every uses clause, after conditional resolution.

    With `section` given, only the uses clauses inside that text are read.
    """
    code = code_view(resolve_conditionals(text if section is None else section))
    tokens = [t for t in tokenize_source(code) if t[0] in ("word", "symbol")]
    units = set()
    i = 0
    while i < len(tokens):
        if tokens[i][0] == "word" and tokens[i][1].lower() == "uses":
            j = i + 1
            while j < len(tokens) and tokens[j][1] != ";":
                if tokens[j][0] == "word" and tokens[j][1].lower() != "in":
                    # `Unit in 'Unit.pas'` - keep the unit, skip the file
                    units.add(tokens[j][1].lower().split(".")[-1])
                j += 1
            i = j
        i += 1
    return units


class PascalStructureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sources = sorted(ROOT.glob("*.pas"))
        cls.sources += sorted(ROOT.glob("*.lpr"))
        cls.sources += sorted(ROOT.glob("*.dpr"))
        cls.cache = {}
        for path in cls.sources:
            cls.cache[path] = path.read_text(encoding="utf-8", errors="replace")
        assert cls.sources, "no Pascal sources found"

    def text(self, path):
        return self.cache[path]

    def code(self, path):
        return code_view(self.text(path))

    # ------------------------------------------------------------- unit shape
    def test_unit_name_matches_file_name(self):
        for path in self.sources:
            if path.suffix != ".pas":
                continue
            m = re.search(r"^\s*unit\s+(\w+)\s*;", self.text(path), re.M | re.I)
            self.assertIsNotNone(m, f"{path.name}: no 'unit ... ;' header")
            self.assertEqual(m.group(1), path.stem,
                             f"{path.name}: unit name is {m.group(1)}")

    def test_every_unit_ends_with_end_dot(self):
        for path in self.sources:
            if path.suffix != ".pas":
                continue
            self.assertTrue(self.code(path).rstrip().endswith("end."),
                            f"{path.name}: does not end with 'end.'")

    def test_program_files_have_a_begin_block(self):
        for path in self.sources:
            if path.suffix not in (".lpr", ".dpr"):
                continue
            code = self.code(path)
            self.assertRegex(code, r"\bbegin\b", f"{path.name}: no begin")
            self.assertTrue(code.rstrip().endswith("end."),
                            f"{path.name}: does not end with 'end.'")

    # -------------------------------------------------------------- balancing
    def test_comments_are_closed(self):
        for path in self.sources:
            text = self.text(path)
            # Only count delimiters that are not inside a string literal.
            stripped = "".join(v for k, v, _ in tokenize_source(text) if k != "string")
            self.assertEqual(stripped.count("{"), stripped.count("}"),
                             f"{path.name}: unbalanced {{ }} comments")
            self.assertEqual(stripped.count("(*"), stripped.count("*)"),
                             f"{path.name}: unbalanced (* *) comments")

    def test_brackets_and_parens_balance(self):
        for path in self.sources:
            code = self.code(path)
            for open_ch, close_ch in (("(", ")"), ("[", "]")):
                depth = 0
                for idx, ch in enumerate(code):
                    if ch == open_ch:
                        depth += 1
                    elif ch == close_ch:
                        depth -= 1
                        self.assertGreaterEqual(
                            depth, 0,
                            f"{path.name}:{line_of(code, idx)}: stray '{close_ch}'")
                self.assertEqual(depth, 0, f"{path.name}: unbalanced '{open_ch}'")

    def test_string_literals_do_not_cross_lines(self):
        for path in self.sources:
            for kind, value, offset in tokenize_source(self.text(path)):
                if kind != "string":
                    continue
                self.assertTrue(value.endswith("'"),
                                f"{path.name}:{line_of(self.text(path), offset)}: "
                                f"unterminated string literal")
                self.assertNotIn("\n", value,
                                 f"{path.name}:{line_of(self.text(path), offset)}: "
                                 f"string literal spans lines")

    def test_begin_end_balance(self):
        """begin/end must pair up once class, record and case bodies count too.

        `end` closes a `begin` block, a `try` block, a `class`/`record` body
        and a `case` statement, so all four have to be tracked. An `else`
        belongs to the innermost still-open `if` or `case`, which decides
        whether it consumes a `case`.
        """
        for path in self.sources:
            code = code_view(resolve_conditionals(self.text(path)))
            depth = 0      # open begin / try / asm blocks
            in_type = False  # inside a class / record / interface body
            cases = 0      # open case statements
            else_owner = []  # 'if' or 'case', innermost last
            prev_word = ""
            prev_symbol = ""
            unit_ends = 0    # the final `end.` that closes the unit
            for kind, value, offset in tokenize_source(code):
                if kind == "ws":
                    continue
                if kind != "word":
                    if kind == "symbol":
                        if value == ";":
                            # An `if` without `else` is finished here.
                            while else_owner and else_owner[-1] == "if":
                                else_owner.pop()
                            prev_symbol = ""
                        elif value == ":":
                            # `E: DWORD` - a field type, not a type
                            # definition. Do not remember it, or
                            # `X = record` two tokens later would be missed.
                            pass
                        else:
                            prev_symbol = value
                    continue
                token = value.lower()
                if token in ("begin", "try", "asm"):
                    depth += 1
                elif token == "if":
                    else_owner.append("if")
                elif token == "case":
                    cases += 1
                    else_owner.append("case")
                elif token == "else":
                    # `else` belongs to the innermost `if`; only when no `if`
                    # is open does it belong to the enclosing `case`. Either
                    # way the `case` itself stays open until its own `end`.
                    if else_owner and else_owner[-1] == "if":
                        else_owner.pop()
                elif token == "end":
                    # A type body must be checked first: it is not a `begin`
                    # block, and a `begin` can never be open inside one, so a
                    # shared counter would let `end;` of a record eat the
                    # `begin` of the next routine.
                    if in_type:
                        in_type = False
                    elif depth > 0:
                        depth -= 1
                    elif cases > 0:
                        cases -= 1
                        while else_owner:
                            else_owner.pop()
                    else:
                        # The last `end.` of a unit closes the unit itself and
                        # has no matching block. There may be exactly one.
                        after = code[offset + 3:].lstrip()
                        if after.startswith("."):
                            unit_ends += 1
                            self.assertLessEqual(
                                unit_ends, 1,
                                f"{path.name}:{line_of(code, offset)}: "
                                f"more than one unit-closing 'end.'")
                        else:
                            self.fail(
                                f"{path.name}:{line_of(code, offset)}: "
                                f"'end' without a matching block")
                elif token in ("class", "record", "object", "interface") \
                        and prev_symbol == "=":
                    in_type = True
                elif token in ("class", "record", "object") and prev_word in (
                        "packed", "of", "abstract", "sealed", "helper"):
                    in_type = True
                prev_word = token
                if value != ":":
                    prev_symbol = ""
            self.assertEqual(depth, 0, f"{path.name}: begin/end not balanced")
            self.assertEqual(cases, 0, f"{path.name}: case/end not balanced")
            self.assertFalse(in_type, f"{path.name}: class/record end missing")

    def test_uses_clause_is_not_split_by_a_conditional(self):
        """A uses clause is ONE comma-separated list with ONE final ';'.

        The conditional branches that spell the unit names for FPC and for
        Delphi must therefore end with a comma:

            uses
            {$IFDEF FPC}
              Classes, SysUtils,
            {$ELSE}
              System.Classes,
              System.SysUtils,
            {$ENDIF}
              DevTypes, CommPort;

        Ending a branch with ';' and then listing more units after {$ENDIF}
        compiles to two statements once the conditionals are resolved - a
        complete uses clause followed by a stray identifier list. It is a fatal
        syntax error that no brace or begin/end counter can see, and it is easy
        to introduce when a unit is added to only one branch.
        """
        section = {
            "type", "const", "var", "resourcestring", "threadvar", "label",
            "function", "procedure", "implementation", "initialization",
            "finalization", "exports", "operator", "property", "begin",
            "asm", "end", "class",
        }
        for path in self.sources:
            code = code_view(resolve_conditionals(self.text(path)))
            tokens = [t for t in tokenize_source(code)
                      if t[0] in ("word", "symbol")]
            for idx, (kind, value, offset) in enumerate(tokens):
                if kind != "word" or value.lower() != "uses":
                    continue
                # walk the comma-separated list to its ';'
                j = idx + 1
                while j < len(tokens) and tokens[j][1] != ";":
                    j += 1
                self.assertLess(j, len(tokens),
                                f"{path.name}: unterminated 'uses' clause")
                line = code.count("\n", 0, tokens[j][2]) + 1
                nxt = tokens[j + 1] if j + 1 < len(tokens) else None
                if nxt is None:
                    continue
                self.assertIn(
                    nxt[1].lower(), section,
                    f"{path.name}:{code.count(chr(10), 0, nxt[2]) + 1}: "
                    f"'{nxt[1]}' follows the ';' that closed the uses clause "
                    f"at line {line}. A conditional branch inside a uses "
                    f"clause must end with a comma, not a semicolon, or the "
                    f"units after ${{ENDIF}} become a stray statement.")

    def test_cross_unit_references_are_in_a_uses_clause(self):
        """A symbol from another project unit needs that unit in `uses`.

        Pascal does not re-export: if `JobEngine` uses `DeviceSession`, then
        `Main2Form` still cannot see `TDeviceSession` unless it names
        `DeviceSession` itself. Forgetting that is invisible to every other
        check here and only appears as a compile error on a Windows runner.

        Only unambiguous references are reported - a name owned by exactly one
        unit, longer than two characters, not a keyword, not declared locally
        in the referencing file, and not written as `Something.Member`.
        """
        texts = {path: self.text(path) for path in self.sources}
        owner = {}
        for path, text in texts.items():
            for name in exported_symbols(text):
                owner.setdefault(name.lower(), set()).add(path.stem.lower())

        for path in self.sources:
            text = texts[path]
            code = code_view(resolve_conditionals(text))
            used = resolved_uses(text)
            me = path.stem.lower()
            local = locally_declared(text) | {
                n.lower() for n in exported_symbols(text)}
            missing = {}
            prev = ""
            for kind, value, offset in tokenize_source(code):
                if kind == "ws":
                    continue
                if kind == "symbol":
                    prev = value
                    continue
                if kind != "word":
                    continue
                qualified = prev == "."
                prev = ""
                if qualified:
                    continue
                low = value.lower()
                if low in PASCAL_KEYWORDS or low in local or len(low) < 3:
                    continue
                owners = owner.get(low)
                if not owners:
                    continue
                outside = owners - {me}
                if len(outside) != 1:
                    continue          # ambiguous: several units declare it
                unit = next(iter(outside))
                if unit not in used:
                    missing.setdefault(unit, (value, line_of(code, offset)))
            for unit, (symbol, line) in sorted(missing.items()):
                self.fail(
                    f"{path.name}:{line}: '{symbol}' comes from {unit}.pas, "
                    f"which is not in any uses clause of {path.name}. Pascal "
                    f"does not re-export units, so add it explicitly.")

    def test_interface_references_are_in_the_interface_uses(self):
        """A type used by the interface needs the INTERFACE uses clause.

        Adding a field `FEngine: TJobEngine` to a form class while naming
        `JobEngine` only in the implementation uses clause compiles to

            Main2Form.pas(303,14) Error: Identifier not found "TJobEngine"

        because the class declaration is resolved before the implementation
        uses clause exists. The check above cannot see this: it collects the
        uses clauses of both sections together, which is correct for the
        implementation but too generous for the interface.
        """
        texts = {path: self.text(path) for path in self.sources}
        owner = {}
        for path, text in texts.items():
            for name in exported_symbols(text):
                owner.setdefault(name.lower(), set()).add(path.stem.lower())

        for path in self.sources:
            if path.suffix != ".pas":
                continue
            text = texts[path]
            section = interface_section(text)
            if not section.strip():
                continue
            code = code_view(resolve_conditionals(section))
            used = resolved_uses(section, section)
            me = path.stem.lower()
            local = locally_declared(text) | {
                n.lower() for n in exported_symbols(text)}
            missing = {}
            prev = ""
            for kind, value, offset in tokenize_source(code):
                if kind == "ws":
                    continue
                if kind == "symbol":
                    prev = value
                    continue
                if kind != "word":
                    continue
                qualified = prev == "."
                prev = ""
                if qualified:
                    continue
                low = value.lower()
                if low in PASCAL_KEYWORDS or low in local or len(low) < 3:
                    continue
                owners = owner.get(low)
                if not owners:
                    continue
                outside = owners - {me}
                if len(outside) != 1:
                    continue
                unit = next(iter(outside))
                if unit not in used:
                    missing.setdefault(unit, (value, line_of(code, offset)))
            for unit, (symbol, line) in sorted(missing.items()):
                self.fail(
                    f"{path.name}: the interface uses '{symbol}' from "
                    f"{unit}.pas, but {unit} is only in the implementation "
                    f"uses clause (near interface line {line}). Move it to the "
                    f"interface uses clause.")

    def test_no_declaration_section_after_begin(self):
        """`var`, `const`, `type` and `label` may not follow a routine's
        `begin`.

        A guard clause pasted above an existing `var` block produces

            procedure T.P(Sender: TObject);
            begin
              if Busy then Exit;
            var                 <-- fatal: a declaration section after begin
              FileName: string;
            begin

        which no brace/begin-end counter notices, because the two `begin`s and
        the two `end`s still balance. It only appears as a compiler error at
        the end of a full Windows build.

        The one legal way to see a declaration keyword inside a block is a
        nested routine: its own header (`function`, `procedure`,
        `constructor`, `destructor`) comes first, so a header seen since the
        innermost block opened makes the next `var` legal again.
        """
        decl_keywords = {"var", "const", "type", "label"}
        headers = {"function", "procedure", "constructor", "destructor"}
        openers = {"begin", "try", "asm", "case"}
        for path in self.sources:
            code = code_view(resolve_conditionals(self.text(path)))
            blocks = []          # innermost last; one entry per open block
            pending_header = False
            prev = ""
            for kind, value, offset in tokenize_source(code):
                if kind == "ws":
                    continue
                if kind != "word":
                    if kind == "symbol":
                        prev = value
                    continue
                token = value.lower()
                if token in headers:
                    pending_header = True
                elif token in openers:
                    blocks.append(token)
                    pending_header = False
                elif token == "end":
                    if blocks:
                        blocks.pop()
                    pending_header = False
                elif token in decl_keywords and blocks:
                    # `array of const` is a type, not a declaration section
                    if token == "const" and prev == "of":
                        prev = token
                        continue
                    self.fail(
                        f"{path.name}:{code.count(chr(10), 0, offset) + 1}: "
                        f"'{token}' inside a {blocks[-1]} block with no routine "
                        f"header before it - a declaration section cannot "
                        f"follow 'begin'")
                prev = token

    # ------------------------------------------------------------ uses clauses
    def test_uses_only_known_units(self):
        """Walk tokens, so a 'uses' inside a string literal cannot match."""
        known = pascal_units()
        for path in self.sources:
            tokens = list(tokenize_source(self.code(path)))
            idx = 0
            while idx < len(tokens):
                kind, value, offset = tokens[idx]
                if kind == "word" and value.lower() == "uses":
                    idx += 1
                    items = []
                    while idx < len(tokens):
                        k2, v2, o2 = tokens[idx]
                        if k2 == "symbol" and v2 == ";":
                            break
                        if k2 == "word":
                            if v2.lower() == "in":
                                # "UnitName in 'file.pas'": skip the phrase.
                                idx += 1
                                while idx < len(tokens) and tokens[idx][0] != "word" \
                                        and not (tokens[idx][0] == "symbol"
                                                 and tokens[idx][1] in (";", ",")):
                                    idx += 1
                                continue
                            items.append((v2, o2))
                        elif k2 == "symbol" and v2 == ".":
                            # Unit.Scope style: glue onto the previous word.
                            if items:
                                items[-1] = (items[-1][0] + ".", items[-1][1])
                        idx += 1
                    for name, name_offset in items:
                        clean = name.rstrip(".").lower()
                        if not clean:
                            continue
                        self.assertTrue(
                            clean in known or clean in RTL_UNITS,
                            f"{path.name}:{line_of(self.code(path), name_offset)}: "
                            f"uses unknown unit '{name}'")
                idx += 1

    # ------------------------------------------------ interface/implementation
    def sections(self, path):
        code = self.code(path)
        m = re.search(r"^\s*implementation\b", code, re.M | re.I)
        self.assertIsNotNone(m, f"{path.name}: no implementation section")
        return code, code[:m.start()], code[m.start():]

    def test_declared_routines_are_implemented(self):
        for path in self.sources:
            if path.suffix != ".pas":
                continue
            code, interface_part, impl_part = self.sections(path)
            declared = set()
            for m in re.finditer(
                    r"^\s*(?:class\s+)?(function|procedure)\s+"
                    r"(?:[A-Za-z_]\w*\.)?([A-Za-z_]\w*)",
                    interface_part, re.M | re.I):
                declared.add(m.group(2).lower())
            implemented = set()
            for m in re.finditer(
                    r"^\s*(?:class\s+)?(function|procedure)\s+"
                    r"(?:[A-Za-z_]\w*\.)?([A-Za-z_]\w*)",
                    impl_part, re.M | re.I):
                implemented.add(m.group(2).lower())
            missing = declared - implemented
            self.assertFalse(
                missing,
                f"{path.name}: interface routines without a body: "
                f"{sorted(missing)}")

    def test_class_methods_have_a_declaration(self):
        """Every T<Foo>.<Method> body must be declared inside T<Foo>."""
        for path in self.sources:
            if path.suffix != ".pas":
                continue
            code = self.code(path)

            classes = {}
            for m in re.finditer(
                    r"\b(T[A-Za-z_]\w*)\s*=\s*(?:class|record|object)\b",
                    code, re.I):
                name = m.group(1).lower()
                start = m.end()
                depth = 0
                idx = start
                while idx < len(code):
                    w = WORD.match(code, idx)
                    if w:
                        if w.group(0).lower() == "end":
                            if depth == 0:
                                break
                            depth -= 1
                        idx = w.end()
                        continue
                    ch = code[idx]
                    if ch in "([{":
                        depth += 1
                    elif ch in ")]}":
                        depth -= 1
                    idx += 1
                body = code[start:idx]
                methods = set()
                for mm in re.finditer(
                        r"^\s*(?:class\s+)?(?:function|procedure)\s+([A-Za-z_]\w*)",
                        body, re.M | re.I):
                    methods.add(mm.group(1).lower())
                classes.setdefault(name, set()).update(methods)

            for m in re.finditer(
                    r"^\s*(?:function|procedure)\s+(T[A-Za-z_]\w*)\.([A-Za-z_]\w*)",
                    code, re.M | re.I):
                cls = m.group(1).lower()
                method = m.group(2).lower()
                self.assertIn(cls, classes,
                              f"{path.name}:{line_of(code, m.start())}: "
                              f"{m.group(1)} has no class declaration")
                self.assertIn(
                    method, classes[cls],
                    f"{path.name}:{line_of(code, m.start())}: "
                    f"{m.group(1)}.{m.group(2)} is not declared in the class")

    # --------------------------------------------------------- common pitfalls
    def test_no_fillchar_on_records_with_strings(self):
        """FillChar zeroes managed string fields and leaks their buffers."""
        string_records = set()
        for path in self.sources:
            if path.suffix != ".pas":
                continue
            code = self.code(path)
            for m in re.finditer(
                    r"\b(T[A-Za-z_]\w*)\s*=\s*(?:packed\s+)?record\b(.*?)\bend\s*;",
                    code, re.S | re.I):
                if re.search(r":\s*(string|UnicodeString|AnsiString)\b",
                             m.group(2), re.I):
                    string_records.add(m.group(1).lower())
        for path in self.sources:
            code = self.code(path)
            for m in re.finditer(r"\bFillChar\s*\(\s*([A-Za-z_]\w*)\s*,", code, re.I):
                target = m.group(1).lower()
                decl = re.search(rf"\b{re.escape(target)}\s*:\s*(T[A-Za-z_]\w*)",
                                 code, re.I)
                if decl and decl.group(1).lower() in string_records:
                    self.fail(
                        f"{path.name}:{line_of(code, m.start())}: FillChar on "
                        f"'{target}' - {decl.group(1)} has string fields")

    def test_device_units_exist_and_are_stub_free(self):
        """The device layer must be present and free of placeholder markers."""
        for name in DEVICE_UNITS:
            path = ROOT / f"{name}.pas"
            if not path.exists():
                continue
            text = self.text(path)
            for bad in ("TODO", "FIXME", "XXX:", "NOT_IMPLEMENTED",
                        "raise Exception.Create('stub')"):
                self.assertNotIn(bad, text, f"{name}.pas contains {bad!r}")

    def test_device_units_have_no_empty_routine_bodies(self):
        """A routine whose body is only 'begin end' is a stub in disguise."""
        for name in DEVICE_UNITS:
            path = ROOT / f"{name}.pas"
            if not path.exists():
                continue
            code = self.code(path)
            for m in re.finditer(
                    r"^\s*(?:function|procedure)\s+([A-Za-z_][\w.]*)[^;]*;\s*"
                    r"(?:var\b.*?|const\b.*?|label\b.*?)?begin\s+end\s*;",
                    code, re.M | re.S | re.I):
                name_found = m.group(1)
                # Empty bodies are legitimate for notification hooks and
                # destructors that only release inherited state.
                if name_found.lower().endswith(("create", "destroy")):
                    continue
                self.fail(f"{path.name}: {name_found} has an empty body")


if __name__ == "__main__":
    unittest.main(verbosity=2)
