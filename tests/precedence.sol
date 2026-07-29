fn main() {
    fwrite(stdout, 2 + 3 * 4); // Expect: 14
    fwrite(stdout, "\n");
    fwrite(stdout, 20 - 3 * 4); // Expect: 8
    fwrite(stdout, "\n");
    fwrite(stdout, 2 + 6 / 3); // Expect: 4
    fwrite(stdout, "\n");
    fwrite(stdout, 2 - 6 / 3); // Expect: 0
    fwrite(stdout, "\n");
    fwrite(stdout, (2 * (6 - (2 + 2)))); // Expect: 4
    fwrite(stdout, "\n"); 
}