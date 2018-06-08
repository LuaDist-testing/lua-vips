#!/usr/bin/env luajit

vips = require 'vips'

size = 1024

-- perlin's "turbulence" image
function turbulence(size)
    local image = nil
    local iterations = math.log(size, 2) - 2
    for i = 0, iterations do
        -- make perlin noise at this scale
        local layer = vips.Image.perlin(size, size, 
            {cell_size = size / math.pow(2, i)})
        layer = layer:abs() * (1.0 / (i + 1))

        -- and sum
        if image then
            image = image + layer
        else
            image = layer
        end
    end

    return image
end

-- make a gradient colour map ... a smooth fade from start to stop, with 
-- start and stop as CIELAB colours, then map as sRGB
function gradient(start, stop)
    local lut = vips.Image.identity() / 255
    lut = lut * start + (lut * -1 + 1) * stop
    return lut:colourspace("srgb", {source_space = "lab"})
end

-- make a turbulent stripe pattern
stripe = vips.Image.xyz(size, size):extract_band(0)
stripe = (stripe * 360 * 4 / size + turbulence(size) * 700):sin()

-- make a colour map ... we want a smooth gradient from white to dark brown
-- colours here in CIELAB
dark_brown = {7.45, 4.3, 8}
white = {100, 0, 0}
lut = gradient(dark_brown, white)

-- rescale to 0 - 255 and colour with our lut
stripe = ((stripe + 1) * 128):maplut(lut)

print("writing x.png ...")
stripe:write_to_file("x.png")
