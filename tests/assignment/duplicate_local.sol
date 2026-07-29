fn main() {
    var a = "value";
    var a = "other"; // Expect: Error Cannot redeclare local variable 'a' in the same scope.
    fwrite(stdout, a);
    fwrite(stdout, "\n");
}