// Example stdio lib
fn print(msg) {
    fwrite(stdout, msg);
}
fn println(msg) {
    fwrite(stdout, msg);
    fwrite(stdout, "\n");
}

fn readln() {
    return fread(stdin, "*l");
}