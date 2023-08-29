use opencv::prelude::*;
use opencv::{
    core::{self, Point},
    imgcodecs, imgproc,
};
use std::collections::{HashMap, HashSet};
use std::f64::consts::PI;
use std::hash::{Hash, Hasher};

#[rustler::nif]
fn detect_chessboard(image_file: String) -> Vec<String> {
    // grayscale
    let image = imgcodecs::imread(&image_file, imgcodecs::IMREAD_GRAYSCALE)
        .expect("Image file could not be read");
    save_image("grayscale.jpg", &image);

    // canny edge detection
    let mut edges = image.clone();
    imgproc::canny(&image, &mut edges, 150.0, 190.0, 3, false).expect("Failed to execute canny");
    save_image("edges.jpg", &edges);

    // hough line transform
    let lines = detect_lines(edges.clone(), &edges);

    // cleanup lines
    let max_width = image.rows();
    let mut polar_lines = convert_to_polar_lines(&lines, max_width as f32);
    let polar_set: HashSet<PolarLine> = HashSet::from_iter(polar_lines.iter().cloned());
    polar_lines = normalize_to_origin(polar_set, max_width);
    polar_lines = add_border_lines(polar_lines, max_width);
    polar_lines.sort_by_key(|l| (l.start.x, l.start.y));
    save_lines_image(&polar_lines, &edges);

    // crop square images
    let intersections = find_intersections(polar_lines, max_width);
    crop_board_squares_and_save(intersections, image, max_width)
}

fn detect_lines(mut lines: Mat, edges: &Mat) -> Mat {
    let threshold = 1150; // fine tuned for the digital images
    imgproc::hough_lines(
        &edges,
        &mut lines,
        1.0,
        PI / 180.0,
        threshold,
        0.0,
        0.0,
        0.0,
        PI,
    )
    .expect("Failed to execute hough_lines");
    lines
}

#[derive(PartialEq, Eq, Clone, Debug)]
struct PolarLine {
    start: Point,
    end: Point,
}

impl PolarLine {
    fn new(start: Point, end: Point) -> Self {
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
            let pt1 = Point::new((x + max_width * -b) as i32, (y + max_width * a) as i32);
            let pt2 = Point::new((x - max_width * -b) as i32, (y - max_width * a) as i32);
            polar_lines.push(PolarLine::new(pt1, pt2));
        }
    }
    polar_lines
}

fn normalize_to_origin(line_set: HashSet<PolarLine>, max_width: i32) -> Vec<PolarLine> {
    let mut lines = Vec::from_iter(line_set.iter().cloned());
    for line in &mut lines {
        if line.start.x == -max_width {
            line.start = Point::new(0, line.start.y);
        } else if line.end.y == -max_width {
            line.end = Point::new(line.end.x, 0);
        }
    }
    lines
}

// HACK: add for manually cropped digital picture
fn add_border_lines(mut lines: Vec<PolarLine>, max_width: i32) -> Vec<PolarLine> {
    let top_border = PolarLine::new(Point::new(0, 0), Point::new(max_width, 0));
    let bottom_border = PolarLine::new(Point::new(0, max_width), Point::new(max_width, max_width));
    let left_border = PolarLine::new(Point::new(0, max_width), Point::new(0, 0));
    let right_border = PolarLine::new(Point::new(max_width, max_width), Point::new(max_width, 0));

    if !lines.contains(&top_border) {
        lines.push(top_border);
    }
    if !lines.contains(&bottom_border) {
        lines.push(bottom_border);
    }
    if !lines.contains(&left_border) {
        lines.push(left_border);
    }
    if !lines.contains(&right_border) {
        lines.push(right_border);
    }
    lines
}

fn find_intersections(lines: Vec<PolarLine>, max_width: i32) -> Vec<Vec<Point>> {
    let (horizontal_lines, vertical_lines) = partition_horizontal_and_vertical_lines(lines);
    let mut horizontal_intersections = Vec::new();

    for h_line in horizontal_lines {
        let mut v_intersections = Vec::new();
        for v_line in &vertical_lines {
            let v_x = v_line.start.x;
            if (0..max_width + 1).contains(&v_x) {
                v_intersections.push(Point::new(v_x, h_line.end.y));
            }
        }
        horizontal_intersections.push(v_intersections);
    }
    horizontal_intersections
}

fn partition_horizontal_and_vertical_lines(
    lines: Vec<PolarLine>,
) -> (Vec<PolarLine>, Vec<PolarLine>) {
    let mut horizontal_lines = Vec::new();
    let mut vertical_lines = Vec::new();
    for line in lines {
        if line.start.x == 0 && line.end.x != 0 {
            horizontal_lines.push(line)
        } else {
            vertical_lines.push(line)
        }
    }
    (horizontal_lines, vertical_lines)
}

fn crop_board_squares_and_save(
    intersections: Vec<Vec<Point>>,
    image: Mat,
    max_width: i32,
) -> Vec<String> {
    let mut filenames = Vec::new();
    let dimensions = max_width / 8;
    for (h_int_idx, h_int) in intersections.iter().enumerate() {
        for (point_idx, point) in h_int.iter().enumerate() {
            if point_idx + 1 < h_int.len() {
                // let end_x = h_int[point_idx + 1].x;
                if h_int_idx + 1 < intersections.len() {
                    // let end_y = intersections[h_int_idx + 1][point_idx].y;
                    let cropped = Mat::roi(
                        &image,
                        core::Rect {
                            x: point.x,
                            y: point.y,
                            // width: end_x - point.x,
                            // height: end_y - point.y,
                            width: dimensions,
                            height: dimensions,
                        },
                    )
                    .expect("Cropping failed");

                    if cropped.size().unwrap().width != 0 {
                        let filename = format_filename(h_int_idx, point_idx);
                        save_image(&format!("squares/{}", filename), &cropped);
                        filenames.push(filename);
                    } else {
                        panic!("Cropped has no size");
                    }
                }
            }
        }
    }
    filenames
}

fn format_filename(row: usize, col: usize) -> String {
    // println!("row {} - col {}", row, col);
    let row_map = HashMap::from([
        (0, "8"),
        (1, "7"),
        (2, "6"),
        (3, "5"),
        (4, "4"),
        (5, "3"),
        (6, "2"),
        (7, "1"),
    ]);
    let col_map = HashMap::from([
        (0, "a"),
        (1, "b"),
        (2, "c"),
        (3, "d"),
        (4, "e"),
        (5, "f"),
        (6, "g"),
        (7, "h"),
    ]);
    format!("{}{}.jpg", col_map[&col], row_map[&row])
}

fn save_lines_image(lines: &Vec<PolarLine>, edges: &core::Mat) {
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
    std::fs::create_dir_all("image_output/squares")
        .expect("Failed to create 'image_output/squares'");

    let write_params = core::Vector::new();
    let filepath = format!("image_output/{}", filename);
    let failure = format!("Failed to write {}", filename);
    imgcodecs::imwrite(&filepath, &image, &write_params).expect(&failure);
}

rustler::init!("Elixir.ChessVision.ImageRecognition", [detect_chessboard]);
