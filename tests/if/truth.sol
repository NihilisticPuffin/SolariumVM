fn main() {
    if (false) fwrite(stdout, "bad\n"); else fwrite(stdout, "false\n"); // expect: false
    if (null) fwrite(stdout, "bad\n"); else fwrite(stdout, "null\n"); // expect: nil
    if (0) fwrite(stdout, "bad\n"); else fwrite(stdout, "0\n"); // expect: 0

    if (true) fwrite(stdout, "true\n"); // expect: true
    if ("") fwrite(stdout, "empty\n"); // expect: empty
    if (1) fwrite(stdout, "1\n"); // expect: 1
}