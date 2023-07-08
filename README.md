# Chess Vision
Convert an image of a chessboard into a digital representation

## Battle Plan
* LiveView to capture image and store it. File or S3?
* Parse image into array of images of 64 squares
  - Canny edge detection - Rust nif
  - Hough line detection - Rust nif
  - order is important: top left of board will be element 0
    - orientation is not guaranteed; A1 could be any corner of the board
* Convert each of those images into data points by feeding them to an image recognition neural network
  - train NN
    - training/test sets of tactics book images and live board images. Use step 1 to help with this.
    - Use Nx
  - output is array of structs containing { piece_type, piece_color, square_color }
* Convert that data into a FEN string
  - figure out how to determine orientation of the board
    - require picture to be taken at a certain orientation if needed
  - https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
  - example after 1. e4: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
* Render FEN string as a chess board in the web app UI
  - use chess.js to take a FEN string and display the board accordingly
    - https://github.com/jhlywa/chess.js
  - display FEN string along side original image
