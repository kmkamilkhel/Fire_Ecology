// ===================== USER INPUTS =====================
var geometry = /* your geometry */;
var startDate = '2023-01-01';
var endDate = '2023-12-31';
var exportDescription = 'Fire_Indices_Composite';
var exportFolder = 'Fire_Export';
// =======================================================


// Cloud masking function based on SCL band (Sentinel-2 Level-2A)
function cloudMask(image) {
  var scl = image.select('SCL');
  var mask = scl.eq(3).or(scl.gte(7).and(scl.lte(10))).eq(0); // Exclude cloud, cirrus, and shadow
  return image
    .select(['B2', 'B3', 'B4', 'B6', 'B7', 'B8', 'B8A', 'B9', 'B11', 'B12'])
    .divide(10000)
    .updateMask(mask);
}


// ===================== INDEX FUNCTIONS =====================

// Normalized Burn Ratio (NBR)
function calculateNBR(image) {
  return image.normalizedDifference(['B8', 'B11']).rename('NBR');
}

// NBR2
function calculateNBR2(image) {
  return image.normalizedDifference(['B8A', 'B12']).rename('NBR2');
}

// NDVI
function calculateNDVI(image) {
  return image.normalizedDifference(['B8', 'B4']).rename('NDVI');
}

// NDWI
function calculateNDWI(image) {
  return image.normalizedDifference(['B8', 'B11']).rename('NDWI');
}

// VARI
function calculateVARI(image) {
  return image.expression(
    '(G - R) / (G + R + 0.0001)', {
      'G': image.select('B3'),
      'R': image.select('B4')
    }).rename('VARI');
}

// MSAVI
function calculateMSAVI(image) {
  return image.expression(
    '((2 * NIR + 1) - sqrt((2 * NIR + 1)^2 - 8 * (NIR - R))) / 2', {
      'NIR': image.select('B8').toFloat(),
      'R': image.select('B4').toFloat()
    }).rename('MSAVI');
}

// BAIS2
function calculateBAIS2(image) {
  return image.expression(
    '(1 - sqrt((B06 * B07 * B8A) / B04)) * ((B12 - B8A) / sqrt(B12 + B8A) + 1)', {
      'B04': image.select('B4').toFloat(),
      'B06': image.select('B6').toFloat(),
      'B07': image.select('B7').toFloat(),
      'B8A': image.select('B8A').toFloat(),
      'B12': image.select('B12').toFloat()
    }).rename('BAIS2');
}

// MIRBI
function calculateMIRBI(image) {
  return image.expression(
    '10 + SWIR2 + (9.8 * SWIR1)', {
      'SWIR1': image.select('B11'),
      'SWIR2': image.select('B12')
    }).rename('MIRBI');
}

// CSI
function calculateCSI(image) {
  return image.expression(
    'NIR / SWIR1', {
      'NIR': image.select('B8'),
      'SWIR1': image.select('B11')
    }).rename('CSI');
}


// ===================== IMAGE PROCESSING =====================

// Load Sentinel-2 imagery and apply cloud masking
var s2 = ee.ImageCollection('COPERNICUS/S2_SR')
  .filterBounds(geometry)
  .filterDate(startDate, endDate)
  .map(cloudMask)
  .median()
  .clip(geometry);

// Calculate fire-related indices
var indices = ee.Image.cat([
  calculateNBR(s2),
  calculateNBR2(s2),
  calculateNDVI(s2),
  calculateNDWI(s2),
  calculateVARI(s2),
  calculateMSAVI(s2),
  calculateBAIS2(s2),
  calculateMIRBI(s2),
  calculateCSI(s2)
]).toFloat();


// ===================== VISUALIZATION =====================
Map.centerObject(geometry, 10);
Map.addLayer(indices.select('NBR'), {min: -1, max: 1, palette: ['white', 'black', 'red']}, 'NBR');
Map.addLayer(indices.select('NDVI'), {min: -1, max: 1, palette: ['blue', 'white', 'green']}, 'NDVI');
Map.addLayer(indices.select('BAIS2'), {min: 0, max: 1, palette: ['blue', 'yellow', 'red']}, 'BAIS2');
// Add other layers similarly if needed...


// ===================== EXPORT =====================
Export.image.toDrive({
  image: indices,
  description: exportDescription,
  scale: 10,
  region: geometry,
  crs: 'EPSG:4326',
  folder: exportFolder,
  fileFormat: 'GeoTIFF',
  maxPixels: 1e13
});
