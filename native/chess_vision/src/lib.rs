use image::{GrayImage, ImageBuffer, RgbImage};

#[rustler::nif]
fn canny_edge_detection(image_path: String) {
    let priv_image_path = format!("priv/static{}", image_path);

    // Load an image using the `image` crate
    let bytes = std::fs::read(priv_image_path).unwrap();
    let reader = image::io::Reader::new(std::io::Cursor::new(bytes))
        .with_guessed_format()
        .expect("Cursor failed");
    let image = reader.decode().expect("Decoding failed");

    // Perform Canny edge detection with specified parameters
    let sigma = 1.0;
    let high_threshold = 100;
    let low_threshold = 50;
    let edges = _canny_edge_detection(&image, sigma, high_threshold, low_threshold);

    // Save the resulting edges image
    edges
        .save("../../priv/static/edges.jpg")
        .expect("Failed to save image");
}

fn _canny_edge_detection(
    image: &RgbImage,
    sigma: f32,
    high_threshold: u8,
    low_threshold: u8,
) -> RgbImage {
    let grayscale = image.into_luma();
    // let blurred = gaussian_blur::<f32>(&grayscale, sigma);
    // let (gradient_magnitude, gradient_direction) = calculate_gradients(&blurred);
    // let suppressed = non_maximum_suppression(&gradient_magnitude, &gradient_direction);
    // let edges = double_thresholding(&suppressed, high_threshold, low_threshold);

    ImageBuffer::from_fn(image.width(), image.height(), |x, y| {
        let edge_pixel = edges[(y as u32, x as u32)];
        image::Rgb([edge_pixel, edge_pixel, edge_pixel])
    })
}

rustler::init!(
    "Elixir.ChessVision.ImageRecognition",
    [canny_edge_detection]
);
