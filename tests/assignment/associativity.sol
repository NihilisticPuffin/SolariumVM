fn main() {
    var a = "a";
    var b = "b";
    var c = "c";

    a = b = c;

    fwrite(stdout, a); // Expect: c
    fwrite(stdout, "\n");
    fwrite(stdout, b); // Expect: c
    fwrite(stdout, "\n");
    fwrite(stdout, c); // Expect: c
    fwrite(stdout, "\n");
}