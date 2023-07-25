#[rustler::nif]
fn canny_edge_detection(image_path: String) {
    let priv_image_path = format!("priv/static{}", image_path);

    // Load an image using the `image` crate
    let bytes = std::fs::read(priv_image_path).unwrap();
    let reader = image::io::Reader::new(std::io::Cursor::new(bytes))
        .with_guessed_format()
        .expect("Cursor failed");
    let grayscale_image = reader.decode().expect("Decoding failed").into_luma8();

    // Get median pixel value
    // for pixel in grayscale_image.pixels {
    //   let val = pixel.0[0];
    // }

    // Perform Canny edge detection with specified parameters
    let high_threshold = 100.0;
    let low_threshold = 50.0;
    let edges = imageproc::edges::canny(&grayscale_image, low_threshold, high_threshold);

    // Save the resulting edges image
    edges
        .save("image_output/edges.jpg")
        .expect("Failed to save image");
}

rustler::init!(
    "Elixir.ChessVision.ImageRecognition",
    [canny_edge_detection]
);
