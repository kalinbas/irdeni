import { promises as fs } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import iconv from 'iconv-lite'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const webRoot = path.resolve(__dirname, '..')
const repoRoot = path.resolve(webRoot, '..')
const originalRoot = path.join(repoRoot, 'd_irdeni')
const canonicalMapDir = path.join(originalRoot, 'map')
const fallbackMapDir = path.join(originalRoot, 'Sicherheitsordner')
const goldEventFile = path.join(originalRoot, 'ird_gold', 'DATA.SBT')
const outputDataDir = path.join(webRoot, 'public', 'game-data')
const outputMapsDir = path.join(outputDataDir, 'maps')
const outputAssetDir = path.join(webRoot, 'public', 'game-assets')

const assetFiles = [
  'sprites1.bmp',
  'sprites2.bmp',
  'sprites3.bmp',
  'sprites4.bmp',
  'sprites5.bmp',
  'sprites6.bmp',
  'leer.bmp',
  'anisprit.bmp',
  'anim.bmp',
  'rahmen.bmp',
  'logo.bmp',
  'logo2.bmp',
  'todessch.bmp',
  'hinger3.bmp',
]

function normalizeLine(line) {
  if (line.startsWith('"') && line.endsWith('"')) {
    return line.slice(1, -1)
  }

  return line
}

function normalizeFileName(fileName) {
  return fileName.toLowerCase()
}

async function emptyDirectory(directory) {
  await fs.rm(directory, { recursive: true, force: true })
  await fs.mkdir(directory, { recursive: true })
}

async function ensureDirectory(directory) {
  await fs.mkdir(directory, { recursive: true })
}

function parseMapFile(contents, fileName, source) {
  const tokens = contents.replace(/\r/g, ' ').trim().split(/\s+/)
  let cursor = 0

  const width = Number(tokens[cursor++])
  const height = Number(tokens[cursor++])
  const rows = []

  for (let y = 0; y < height; y += 1) {
    const row = []

    for (let x = 0; x < width; x += 1) {
      row.push({
        terrain: Number(tokens[cursor++]),
        event: Number(tokens[cursor++]),
        object: Number(tokens[cursor++]),
      })
    }

    rows.push(row)
  }

  const startX = Number(tokens[cursor++])
  const startY = Number(tokens[cursor++])
  const outsideTile = Number(tokens[cursor++])

  return {
    name: normalizeFileName(fileName),
    originalName: fileName,
    width,
    height,
    start: { x: startX, y: startY },
    outsideTile,
    source,
    rows,
  }
}

async function collectMapFiles() {
  const canonicalEntries = await fs.readdir(canonicalMapDir)
  const fallbackEntries = await fs.readdir(fallbackMapDir)
  const selectedFiles = new Map()
  const rescuedMaps = []

  for (const entry of canonicalEntries) {
    if (!entry.toLowerCase().endsWith('.map')) {
      continue
    }

    selectedFiles.set(normalizeFileName(entry), {
      fileName: entry,
      sourcePath: path.join(canonicalMapDir, entry),
      source: 'map',
    })
  }

  for (const entry of fallbackEntries) {
    if (!entry.toLowerCase().endsWith('.map')) {
      continue
    }

    const normalized = normalizeFileName(entry)
    if (selectedFiles.has(normalized)) {
      continue
    }

    selectedFiles.set(normalized, {
      fileName: entry,
      sourcePath: path.join(fallbackMapDir, entry),
      source: 'backup',
    })
    rescuedMaps.push(normalized)
  }

  const maps = []

  for (const { fileName, sourcePath, source } of selectedFiles.values()) {
    const contents = await fs.readFile(sourcePath, 'utf8')
    maps.push(parseMapFile(contents, fileName, source))
  }

  maps.sort((left, right) => left.name.localeCompare(right.name))
  rescuedMaps.sort((left, right) => left.localeCompare(right))

  return { maps, rescuedMaps }
}

function splitBufferLines(buffer) {
  const lines = []
  let start = 0

  for (let index = 0; index <= buffer.length; index += 1) {
    if (index !== buffer.length && buffer[index] !== 10) {
      continue
    }

    let line = buffer.subarray(start, index)

    if (line.length > 0 && line[line.length - 1] === 13) {
      line = line.subarray(0, line.length - 1)
    }

    lines.push(line)
    start = index + 1
  }

  return lines
}

function decodeEventLine(line) {
  if (line.length === 0) {
    return ''
  }

  if (line[0] === 35) {
    return iconv.decode(line, 'cp850')
  }

  const decodedBytes = Buffer.alloc(line.length)

  for (let index = 0; index < line.length; index += 1) {
    decodedBytes[index] = (line[index] - 20 + 256) % 256
  }

  return normalizeLine(iconv.decode(decodedBytes, 'cp850'))
}

function parseEventBlocks(buffer) {
  const lines = splitBufferLines(buffer)
  const blocks = []
  let currentId = null
  let currentRuntimeId = null
  let currentLines = []

  function pushCurrentBlock() {
    if (currentId === null) {
      return
    }

    blocks.push({
      id: currentId,
      runtimeId: currentRuntimeId,
      type: Number(currentLines[0] ?? 0),
      lines: currentLines,
    })
  }

  for (const line of lines) {
    const decodedLine = decodeEventLine(line)

    if (decodedLine.startsWith('#')) {
      pushCurrentBlock()
      const runtimeId = Number(decodedLine.slice(1))
      currentRuntimeId = runtimeId
      currentId = (runtimeId - 2) / 3
      currentLines = []
      continue
    }

    if (currentId !== null) {
      currentLines.push(decodedLine)
    }
  }

  pushCurrentBlock()

  const byType = {}
  const referencedMaps = new Set()

  for (const block of blocks) {
    byType[block.type] = (byType[block.type] ?? 0) + 1

    for (const line of block.lines) {
      if (/\.map$/i.test(line)) {
        referencedMaps.add(line.toLowerCase())
      }
    }
  }

  return {
    blocks,
    byType,
    referencedMaps: [...referencedMaps].sort((left, right) => left.localeCompare(right)),
  }
}

async function copyAssets() {
  await emptyDirectory(outputAssetDir)

  for (const fileName of assetFiles) {
    const sourcePath = path.join(originalRoot, fileName)
    const destinationPath = path.join(outputAssetDir, fileName)
    await fs.copyFile(sourcePath, destinationPath)
  }
}

async function writeMaps(maps) {
  await emptyDirectory(outputMapsDir)

  for (const map of maps) {
    const targetFile = path.join(outputMapsDir, `${map.name}.json`)
    await fs.writeFile(targetFile, `${JSON.stringify(map, null, 2)}\n`)
  }
}

async function main() {
  await ensureDirectory(outputDataDir)

  const { maps, rescuedMaps } = await collectMapFiles()
  const eventContents = await fs.readFile(goldEventFile)
  const events = parseEventBlocks(eventContents)
  const availableMapNames = new Set(maps.map((map) => map.name))
  const missingReferencedMaps = events.referencedMaps.filter((mapName) => !availableMapNames.has(mapName))

  await writeMaps(maps)
  await copyAssets()

  const manifest = {
    generatedAt: new Date().toISOString(),
    sourceRoot: path.relative(webRoot, originalRoot),
    eventSource: path.relative(webRoot, goldEventFile),
    rescuedMaps,
    missingReferencedMaps,
    counts: {
      maps: maps.length,
      eventBlocks: events.blocks.length,
      assets: assetFiles.length,
    },
    events: {
      byType: events.byType,
      referencedMaps: events.referencedMaps,
    },
    maps: maps.map((map) => ({
      name: map.name,
      originalName: map.originalName,
      width: map.width,
      height: map.height,
      source: map.source,
      start: map.start,
      outsideTile: map.outsideTile,
    })),
  }

  await fs.writeFile(path.join(outputDataDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
  await fs.writeFile(
    path.join(outputDataDir, 'events.json'),
    `${JSON.stringify(
      events.blocks.map((block) => ({
        id: block.id,
        runtimeId: block.runtimeId,
        type: block.type,
        lines: block.lines,
      })),
      null,
      2,
    )}\n`,
  )
  await fs.writeFile(
    path.join(outputDataDir, 'events.decoded.txt'),
    `${events.blocks
      .map((block) => [`#${block.id} (runtime ${block.runtimeId})`, ...block.lines].join('\n'))
      .join('\n\n')}\n`,
  )

  console.log(`Extracted ${maps.length} maps, ${events.blocks.length} event blocks, and ${assetFiles.length} assets.`)
  if (rescuedMaps.length > 0) {
    console.log(`Recovered backup maps: ${rescuedMaps.join(', ')}`)
  }
  if (missingReferencedMaps.length > 0) {
    console.warn(`Missing referenced maps: ${missingReferencedMaps.join(', ')}`)
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
