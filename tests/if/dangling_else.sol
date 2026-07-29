// A dangling else binds to the right-most if.

fn main() {
    if (true) if (false) fwrite(stdout, "bad\n"); else fwrite(stdout, "good\n"); // expect: good
    if (false) if (true) fwrite(stdout, "bad\n"); else fwrite(stdout, "bad\n");
}