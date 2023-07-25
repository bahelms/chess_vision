use imageproc::map::map_colors;
use imageproc::{edges, hough};

#[rustler::nif]
fn detect_chessboard(image_path: String) {
    let priv_image_path = format!("priv/static{}", image_path);
    let output_dir = std::path::Path::new("image_output");

    // Load an image using the `image` crate
    let bytes = std::fs::read(priv_image_path).unwrap();
    let reader = image::io::Reader::new(std::io::Cursor::new(bytes))
        .with_guessed_format()
        .expect("Cursor failed");

    let grayscale_image = reader.decode().expect("Decoding failed").into_luma8();
    grayscale_image
        .save(&output_dir.join("grayscale.jpg"))
        .expect("Failed to save grayscale image");

    // Get median pixel value
    // for pixel in grayscale_image.pixels {
    //   let val = pixel.0[0];
    // }

    // Perform Canny edge detection with specified parameters
    let high_threshold = 100.0;
    let low_threshold = 50.0;
    let edges = edges::canny(&grayscale_image, low_threshold, high_threshold);
    edges
        .save(&output_dir.join("edges.jpg"))
        .expect("Failed to save edges image");

    // Hough line transform
    let hough_options = hough::LineDetectionOptions {
        vote_threshold: 200,
        suppression_radius: 40,
    };
    let lines = hough::detect_lines(&edges, hough_options);

    // use the np equivalent:
    //   if theta < np.pi / 4 or theta > np.pi - np.pi / 4: <- vertical
    //   use std::f64::consts::PI
    let filtered_lines: Vec<hough::PolarLine> = lines
        .iter()
        .filter(|l| l.angle_in_degrees == 0 || l.angle_in_degrees == 180)
        .filter(|l| l.angle_in_degrees == 90)
        .cloned()
        .collect();

    let white = image::Rgb::<u8>([255, 255, 255]);
    let green = image::Rgb::<u8>([0, 255, 0]);
    let black = image::Rgb::<u8>([0, 0, 0]);

    // Convert edge image to colour
    let color_edges = map_colors(&edges, |p| if p[0] > 0 { white } else { black });

    let lines_image = hough::draw_polar_lines(&color_edges, &filtered_lines, green);
    lines_image
        .save(&output_dir.join("lines.jpg"))
        .expect("Failed to save lines image");
}

rustler::init!("Elixir.ChessVision.ImageRecognition", [detect_chessboard]);
