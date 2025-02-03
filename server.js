const express = require("express");
const bodyParser = require("body-parser");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

// Temporary directory for generated files
const tempDir = path.join(__dirname, "temp");
if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir);

// Middleware
app.use(bodyParser.json());
app.use(express.static("public"));

// Handle STL and PNG generation
app.post("/generate", (req, res) => {
    const {
        cardWidth,
        cardHeight,
        cardThickness,
        radius,
        cardBorderOffset,
        cardBorderThickness,
        bevel,
        lineHeight,
        keyChainHole,
        keyChainPosition,
        textLines,
        mode = "stl", // Default to STL generation
    } = req.body;

    if (!textLines || textLines.length === 0) {
        return res.status(400).send("Text lines are required.");
    }

    // Format text lines for OpenSCAD
    const formattedTextLines = textLines
        .map(([text, size, font]) => `["${text}", ${size}, "${font}"]`)
        .join(", ");

    // Read OpenSCAD template
    const templatePath = path.join(__dirname, "template.scad");
    const template = fs.readFileSync(templatePath, "utf8");

    // Replace placeholders in the template
    const scadContent = template
        .replace("{CARD_W}", cardWidth ?? 0)
        .replace("{CARD_H}", cardHeight ?? 0)
        .replace("{KEY_CHAIN_HOLE}", keyChainHole ?? 0)
        .replace("{KEY_CHAIN_POSITION}", keyChainPosition)
        .replace("{CARD_THICKNESS}", cardThickness ?? 0)
        .replace("{BORDEROFFSET}", cardBorderOffset ?? 0)
        .replace("{BORDERTHICKNESS}", cardBorderThickness ?? 0)
        .replace("{RADIUS}", radius ?? 0)
        .replace("{BEVEL}", bevel ?? 0)
        .replace("{LINEHEIGHT}", lineHeight ?? 0)
        .replace("{TEXT_LINES}", formattedTextLines ?? 0);
    console.log(scadContent);

    // Calculate image size dynamically
    const maxDimension = Math.max(cardWidth, cardHeight) * 1.2; // Add 20% buffer
    const imgSize = Math.ceil(maxDimension * 10); // Scale factor for OpenSCAD (e.g., 10 pixels per mm)


    // File paths
    const timestamp = Date.now();
    const scadFile = path.join(tempDir, `temp_model_${timestamp}.scad`);
    fs.writeFileSync(scadFile, scadContent);

    if (mode === "stl") {
        // STL Generation
        const outputFile = path.join(tempDir, `output_${timestamp}.stl`);
        const command = `openscad -o ${outputFile} ${scadFile}`;
        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error("OpenSCAD Error:", stderr);
                return res.status(500).send("Failed to generate STL.");
            }
            res.json({ fileUrl: `/temp/${path.basename(outputFile)}` });
        });
    } else if (mode === "png") {
        // Generate multiple PNGs
        const views = ["top", "front", "perspective"];
        const promises = views.map((view, index) => {
            const outputFile = path.join(tempDir, `output_${view}_${timestamp}.png`);
            const command = `xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24"  openscad --imgsize=${imgSize},${imgSize} -D mode=${index + 1} -o ${outputFile} ${scadFile}`;
            return new Promise((resolve, reject) => {
                exec(command, (error) => {
                    if (error) return reject(`Failed to generate ${view} view.`);
                    resolve(`/temp/${path.basename(outputFile)}`);
                });
            });
        });

        Promise.all(promises)
            .then((fileUrls) => res.json({ fileUrls }))
            .catch((error) => {
                console.error(error);
                res.status(500).send("Failed to generate previews.");
            });
    }
});


// Serve temporary files
app.use("/temp", express.static(tempDir));

// Start server
app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
