// variables
var canvas, ctx;
var image;
var iMouseX, iMouseY = 1;
var theSelection;
var resize_k = 1;

// define Selection constructor
function Selection(x, y, w, h){
    this.x = x; // initial positions
    this.y = y;
    this.w = w; // and size
    this.h = h;

    this.px = x; // extra variables to dragging calculations
    this.py = y;

    this.csize = 6; // resize cubes size
    this.csizeh = 10; // resize cubes size (on hover)

    this.bHow = [false, false, false, false]; // hover statuses
    this.iCSize = [this.csize, this.csize, this.csize, this.csize]; // resize cubes sizes
    this.bDrag = [false, false, false, false]; // drag statuses
    this.bDragAll = false; // drag whole selection
}

// define Selection draw method
Selection.prototype.draw = function(){

    ctx.strokeStyle = '#000';
    ctx.lineWidth = 2;

    // Если crop ушёл за границы
    if (this.x < 0 || (this.x + this.w) > canvas.width || this.y < 0 || (this.y + this.h) > canvas.height) {
        initialize.crop_beyond = true;
        ctx.strokeStyle = "#ff0000";
    } else {
        initialize.crop_beyond = false;
    }

    ctx.strokeRect(this.x, this.y, this.w, this.h);

    // draw part of original image
    if (this.w > 0 && this.h > 0) {
        ctx.drawImage(image, this.x * resize_k, this.y * resize_k, this.w * resize_k, this.h * resize_k, this.x, this.y, this.w, this.h);
    }

    // draw resize cubes
    ctx.fillStyle = '#fff';
    ctx.fillRect(this.x - this.iCSize[0], this.y - this.iCSize[0], this.iCSize[0] * 2, this.iCSize[0] * 2);
    ctx.fillRect(this.x + this.w - this.iCSize[1], this.y - this.iCSize[1], this.iCSize[1] * 2, this.iCSize[1] * 2);
    ctx.fillRect(this.x + this.w - this.iCSize[2], this.y + this.h - this.iCSize[2], this.iCSize[2] * 2, this.iCSize[2] * 2);
    ctx.fillRect(this.x - this.iCSize[3], this.y + this.h - this.iCSize[3], this.iCSize[3] * 2, this.iCSize[3] * 2);
}

function drawScene() { // main drawScene function
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height); // clear canvas

    // draw source image
    ctx.drawImage(image, 0, 0, ctx.canvas.width, ctx.canvas.height);

    // and make it darker
//        ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
//        ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    // draw selection
    theSelection.draw();
}

// Публичная AMD функция для инициализации crop
// panel      - jQuery DOM-canvas, куда отрисовать картинку
// image_data - URL/base64 картинки
// res_k      - Коэфициент ресайза картинки, чтобы большие картинки влезали в монитор
function initialize(panel, image_data, res_k){
    if (res_k != null){
        resize_k = res_k;
    }

    // loading source image
    image = new Image();
    image.src = image_data;

    // creating canvas and context objects
    canvas = panel[0];
    ctx = canvas.getContext('2d');

    // create initial selection
    theSelection = new Selection(0, 0, 100, 100);

    panel.mousemove(function(e) { // binding mouse move event
        var canvasOffset = $(canvas).offset();
        iMouseX = Math.floor(e.pageX - canvasOffset.left);
        iMouseY = Math.floor(e.pageY - canvasOffset.top);

        // in case of drag of whole selector
        if (theSelection.bDragAll) {
            theSelection.x = iMouseX - theSelection.px;
            theSelection.y = iMouseY - theSelection.py;
        }

        for (var i = 0; i < 4; i++) {
            theSelection.bHow[i] = false;
            theSelection.iCSize[i] = theSelection.csize;
        }

        // hovering over resize cubes
        if (iMouseX > theSelection.x - theSelection.csizeh && iMouseX < theSelection.x + theSelection.csizeh &&
            iMouseY > theSelection.y - theSelection.csizeh && iMouseY < theSelection.y + theSelection.csizeh) {

            theSelection.bHow[0] = true;
            theSelection.iCSize[0] = theSelection.csizeh;
        }
        if (iMouseX > theSelection.x + theSelection.w-theSelection.csizeh && iMouseX < theSelection.x + theSelection.w + theSelection.csizeh &&
            iMouseY > theSelection.y - theSelection.csizeh && iMouseY < theSelection.y + theSelection.csizeh) {

            theSelection.bHow[1] = true;
            theSelection.iCSize[1] = theSelection.csizeh;
        }
        if (iMouseX > theSelection.x + theSelection.w-theSelection.csizeh && iMouseX < theSelection.x + theSelection.w + theSelection.csizeh &&
            iMouseY > theSelection.y + theSelection.h-theSelection.csizeh && iMouseY < theSelection.y + theSelection.h + theSelection.csizeh) {

            theSelection.bHow[2] = true;
            theSelection.iCSize[2] = theSelection.csizeh;
        }
        if (iMouseX > theSelection.x - theSelection.csizeh && iMouseX < theSelection.x + theSelection.csizeh &&
            iMouseY > theSelection.y + theSelection.h-theSelection.csizeh && iMouseY < theSelection.y + theSelection.h + theSelection.csizeh) {

            theSelection.bHow[3] = true;
            theSelection.iCSize[3] = theSelection.csizeh;
        }

        // in case of dragging of resize cubes
        var iFW, iFH, iFX, iFY;
        if (theSelection.bDrag[0]) {
            iFX = iMouseX - theSelection.px;
            iFY = iMouseY - theSelection.py;
            iFW = theSelection.w + theSelection.x - iFX;
            iFH = iFW;
            // Здесь и далее по анологии закомментированные строки позволяют прямоугольное выделение
//                iFH = theSelection.h + theSelection.y - iFY;
        }
        if (theSelection.bDrag[1]) {
            iFX = theSelection.x;
            iFY = iMouseY - theSelection.py;
            iFW = iMouseX - theSelection.px - iFX;
            iFH = iFW;
//                iFH = theSelection.h + theSelection.y - iFY;
        }
        if (theSelection.bDrag[2]) {
            iFX = theSelection.x;
            iFY = theSelection.y;
            iFW = iMouseX - theSelection.px - iFX;
            iFH = iFW;
//                iFH = iMouseY - theSelection.py - iFY;
        }
        if (theSelection.bDrag[3]) {
            iFX = iMouseX - theSelection.px;
            iFY = theSelection.y;
            iFW = theSelection.w + theSelection.x - iFX;
            iFH = iFW;
//                iFH = iMouseY - theSelection.py - iFY;
        }

        if (iFW > theSelection.csizeh * 2 && iFH > theSelection.csizeh * 2) {
            theSelection.w = iFW;
            theSelection.h = iFH;

            theSelection.x = iFX;
            theSelection.y = iFY;
        }

        drawScene();
    });

    panel.mousedown(function(e) { // binding mousedown event
        var canvasOffset = $(canvas).offset();
        iMouseX = Math.floor(e.pageX - canvasOffset.left);
        iMouseY = Math.floor(e.pageY - canvasOffset.top);

        theSelection.px = iMouseX - theSelection.x;
        theSelection.py = iMouseY - theSelection.y;

        if (theSelection.bHow[0]) {
            theSelection.px = iMouseX - theSelection.x;
            theSelection.py = iMouseY - theSelection.y;
        }
        if (theSelection.bHow[1]) {
            theSelection.px = iMouseX - theSelection.x - theSelection.w;
            theSelection.py = iMouseY - theSelection.y;
        }
        if (theSelection.bHow[2]) {
            theSelection.px = iMouseX - theSelection.x - theSelection.w;
            theSelection.py = iMouseY - theSelection.y - theSelection.h;
        }
        if (theSelection.bHow[3]) {
            theSelection.px = iMouseX - theSelection.x;
            theSelection.py = iMouseY - theSelection.y - theSelection.h;
        }


        if (iMouseX > theSelection.x + theSelection.csizeh && iMouseX < theSelection.x+theSelection.w - theSelection.csizeh &&
            iMouseY > theSelection.y + theSelection.csizeh && iMouseY < theSelection.y+theSelection.h - theSelection.csizeh) {

            theSelection.bDragAll = true;
        }

        for (var i = 0; i < 4; i++) {
            if (theSelection.bHow[i]) {
                theSelection.bDrag[i] = true;
            }
        }
    });

    panel.mouseup(function(e) { // binding mouseup event
        theSelection.bDragAll = false;

        for (var i = 0; i < 4; i++) {
            theSelection.bDrag[i] = false;
        }
        theSelection.px = 0;
        theSelection.py = 0;
    });

    drawScene();
}

// Статическая функция для возврата crop
initialize.get_results = function(max_side){
    var temp_ctx, temp_canvas, final_w, final_h;
    // Если передано значение наибольшей стороны картинки как число, то уменьшить картинку пропорционально до оного
    if (typeof max_side === "number" || toString.call(max_side) === "[object Number]") {
        if (theSelection.w >= theSelection.h) {
            final_w = max_side;
            final_h = theSelection.h * max_side / theSelection.w;
        } else {
            final_w = theSelection.w * max_side / theSelection.h;
            final_h = max_side;
        }
    } else {
        final_w = theSelection.w;
        final_h = theSelection.h;
    }
    temp_canvas = document.createElement('canvas');
    temp_ctx = temp_canvas.getContext('2d');
    temp_canvas.width = final_w;
    temp_canvas.height = final_h;
    temp_ctx.drawImage(image, theSelection.x * resize_k, theSelection.y * resize_k, theSelection.w * resize_k, theSelection.h * resize_k, 0, 0, final_w, final_h);
    return temp_canvas.toDataURL("image/jpeg");
};

// Булево значение - crop в пределах картинки/за границей
initialize.crop_beyond = false;

module.exports = initialize;