use opencv::prelude::*;
use opencv::{core, imgcodecs, imgproc};
use std::f64::consts::PI;

#[rustler::nif]
fn detect_chessboard(image_file: String) {
    // grayscale
    let image = imgcodecs::imread(&image_file, imgcodecs::IMREAD_GRAYSCALE)
        .expect("Image file could not be read");
    save_image("grayscale.jpg", &image);

    let max_width = image.rows();

    // canny edge detection
    let mut edges = image.clone();
    imgproc::canny(&image, &mut edges, 150.0, 190.0, 3, false).expect("Failed to execute canny");
    save_image("edges.jpg", &edges);

    // hough line transform
    let mut lines = edges.clone();
    imgproc::hough_lines(&edges, &mut lines, 1.0, PI / 180.0, 1100, 0.0, 0.0, 0.0, PI)
        .expect("Failed to execute hough_lines");
    save_lines_image(lines, &edges, max_width as f32)
}

fn save_lines_image(lines: core::Mat, edges: &core::Mat, max_width: f32) {
    let mut lines_image = edges.clone();
    imgproc::cvt_color(&edges, &mut lines_image, imgproc::COLOR_GRAY2BGR, 0)
        .expect("Failed to convert edges color");

    for row in 0..lines.rows() {
        for col in 0..lines.cols() {
            let line = lines.at_2d::<core::Vec2f>(row, col).unwrap();
            let (pt1, pt2) = convert_to_polar_lines(line, max_width);
            let red = core::Scalar::new(0.0, 0.0, 255.0, 0.0);
            imgproc::line(&mut lines_image, pt1, pt2, red, 3, imgproc::LINE_AA, 0)
                .expect("Failed to draw line");
        }
    }
    save_image("lines.jpg", &lines_image);
}

// converts Hough space (rho, theta) to polar space (x, y)
fn convert_to_polar_lines(line: &core::Vec2f, max_width: f32) -> (core::Point, core::Point) {
    let rho = line[0];
    let theta = line[1];
    let a = theta.cos();
    let b = theta.sin();
    let x = a * rho;
    let y = b * rho;
    let pt1 = core::Point::new((x + max_width * -b) as i32, (y + max_width * a) as i32);
    let pt2 = core::Point::new((x - max_width * -b) as i32, (y - max_width * a) as i32);
    (pt1, pt2)
}

fn save_image(filename: &str, image: &Mat) {
    let write_params = core::Vector::new();
    let filepath = format!("image_output/{}", filename);
    let failure = format!("Failed to write {}", filename);
    imgcodecs::imwrite(&filepath, &image, &write_params).expect(&failure);
}

rustler::init!("Elixir.ChessVision.ImageRecognition", [detect_chessboard]);
