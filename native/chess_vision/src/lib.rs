#[rustler::nif]
fn canny_edge_detection(a: i64, b: i64) -> i64 {
    a + b
}

rustler::init!("Elixir.ChessVision.ImageRecognition", [canny_edge_detection]);
