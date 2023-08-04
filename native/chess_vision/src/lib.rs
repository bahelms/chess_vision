use opencv::prelude::*;
use opencv::{core, imgcodecs, imgproc};
use std::collections::HashSet;
use std::f64::consts::PI;
use std::hash::{Hash, Hasher};

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

    // cleanup lines
    let mut polar_lines = convert_to_polar_lines(&lines, max_width as f32);
    let polar_set: HashSet<PolarLine> = HashSet::from_iter(polar_lines.iter().cloned());
    polar_lines = normalize_to_origin(polar_set, max_width);
    polar_lines.sort_by_key(|l| (l.start.x, l.start.y));
    for line in polar_lines.iter() {
        println!("{}", line);
    }

    save_lines_image(polar_lines, &edges);
}

#[derive(PartialEq, Eq, Clone, Debug)]
struct PolarLine {
    start: core::Point,
    end: core::Point,
}

impl PolarLine {
    fn new(start: core::Point, end: core::Point) -> Self {
        Self { start, end }
    }
}

impl Hash for PolarLine {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.start.x.hash(state);
        self.start.y.hash(state);
        self.end.x.hash(state);
        self.end.y.hash(state);
    }
}

impl std::fmt::Display for PolarLine {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(
            f,
            "({}, {}), ({}, {})",
            self.start.x, self.start.y, self.end.x, self.end.y
        )
    }
}

fn normalize_to_origin(line_set: HashSet<PolarLine>, max_width: i32) -> Vec<PolarLine> {
    let mut lines = Vec::from_iter(line_set.iter().cloned());
    for line in &mut lines {
        if line.start.x == -max_width {
            line.start = core::Point::new(0, line.start.y);
        } else if line.end.y == -max_width {
            line.end = core::Point::new(line.end.x, 0);
        }
    }
    lines
}

// converts Hough space (rho, theta) to polar space (x, y)
fn convert_to_polar_lines(lines: &core::Mat, max_width: f32) -> Vec<PolarLine> {
    let mut polar_lines = Vec::new();
    for row in 0..lines.rows() {
        for col in 0..lines.cols() {
            let line = lines.at_2d::<core::Vec2f>(row, col).unwrap();
            let rho = line[0];
            let theta = line[1];
            let a = theta.cos();
            let b = theta.sin();
            let x = a * rho;
            let y = b * rho;
            let pt1 = core::Point::new((x + max_width * -b) as i32, (y + max_width * a) as i32);
            let pt2 = core::Point::new((x - max_width * -b) as i32, (y - max_width * a) as i32);
            polar_lines.push(PolarLine::new(pt1, pt2));
        }
    }
    polar_lines
}

fn save_lines_image(lines: Vec<PolarLine>, edges: &core::Mat) {
    let mut lines_image = edges.clone();
    imgproc::cvt_color(&edges, &mut lines_image, imgproc::COLOR_GRAY2BGR, 0)
        .expect("Failed to convert edges color");

    let red = core::Scalar::new(0.0, 0.0, 255.0, 0.0);
    for line in lines {
        imgproc::line(
            &mut lines_image,
            line.start,
            line.end,
            red,
            3,
            imgproc::LINE_AA,
            0,
        )
        .expect("Failed to draw line");
    }
    save_image("lines.jpg", &lines_image);
}

fn save_image(filename: &str, image: &Mat) {
    let write_params = core::Vector::new();
    let filepath = format!("image_output/{}", filename);
    let failure = format!("Failed to write {}", filename);
    imgcodecs::imwrite(&filepath, &image, &write_params).expect(&failure);
}

rustler::init!("Elixir.ChessVision.ImageRecognition", [detect_chessboard]);
