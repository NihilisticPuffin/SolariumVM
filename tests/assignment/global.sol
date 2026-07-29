fn get_global() {
    return global;
}

fn main() {
    global = "G";
    fwrite(stdout, get_global()); // Expect: G
    fwrite(stdout, "\n");
}