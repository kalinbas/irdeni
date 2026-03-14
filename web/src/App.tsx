import { useEffect, useEffectEvent, useRef, useState, type CSSProperties } from 'react'
import './App.css'
import { getCurrentLanguage, getDocumentLanguage, getEventFileName, getUiText, readLanguageFromSearch } from './i18n'

const CANVAS_WIDTH = 320
const CANVAS_HEIGHT = 200
const TILE_SIZE = 20
const VIEW_RADIUS_X = 8
const VIEW_RADIUS_Y = 5
const PLAYER_SHEET_INDEX = 10
const TOOL_VALUE = 25
const MAX_BAG_SLOTS = 20
const INVENTORY_SLOT_COUNT = 26
const DIALOG_LINE_LENGTH = 50
const DIALOG_PAGE_LINES = 3
const DIALOG_CHARACTER_DELAY_MS = 30
const MAP_TRANSITION_FADE_MS = 320
const BATTLE_PAUSE_MS = 60 * 16
const BATTLE_PAUSE_POLL_MS = 50
const SAVE_SCHEMA_VERSION = 1
const SAVE_DATABASE_NAME = 'irdeni-web-saves'
const SAVE_STORE_NAME = 'slots'

const TILE_SHEET_FILES = [
  '',
  'sprites1.bmp',
  'sprites2.bmp',
  'sprites3.bmp',
  'sprites4.bmp',
  'sprites5.bmp',
  'sprites6.bmp',
  'leer.bmp',
  'leer.bmp',
  'anisprit.bmp',
  'anim.bmp',
]

type SaveSlotId = 'quicksave'

type Direction = 'up' | 'down' | 'left' | 'right'

const DIRECTION_CONFIG: Record<Direction, { dx: number; dy: number; facing: number; label: string }> = {
  up: { dx: 0, dy: -1, facing: 0, label: 'North' },
  down: { dx: 0, dy: 1, facing: 1, label: 'South' },
  left: { dx: -1, dy: 0, facing: 2, label: 'West' },
  right: { dx: 1, dy: 0, facing: 3, label: 'East' },
}

function getSaveSlotDefinitions() {
  const ui = getUiText(getCurrentLanguage())
  return ui.saveSlots.map((slot) => ({ ...slot })) as Array<{ id: SaveSlotId; label: string; emptyText: string }>
}

type ViewportState = {
  width: number
  height: number
  coarsePointer: boolean
}

function readViewportState(): ViewportState {
  if (typeof window === 'undefined') {
    return {
      width: 1280,
      height: 720,
      coarsePointer: false,
    }
  }

  return {
    width: window.innerWidth,
    height: window.innerHeight,
    coarsePointer: window.matchMedia('(pointer: coarse)').matches || window.navigator.maxTouchPoints > 0,
  }
}

type MapCell = {
  terrain: number
  event: number
  object: number
}

type GameMap = {
  name: string
  originalName: string
  width: number
  height: number
  start: {
    x: number
    y: number
  }
  outsideTile: number
  source: string
  rows: MapCell[][]
}

type Manifest = {
  eventSource: string
  sourceRoot: string
  rescuedMaps: string[]
  missingReferencedMaps: string[]
  counts: {
    maps: number
    eventBlocks: number
    assets: number
  }
  events: {
    byType: Record<string, number>
  }
  maps: Array<{
    name: string
    originalName: string
    width: number
    height: number
    source: string
    start: {
      x: number
      y: number
    }
    outsideTile: number
  }>
}

type EventBlock = {
  id: number
  runtimeId: number
  type: number
  lines: string[]
}

type SpriteSheetSet = {
  opaque: HTMLImageElement
  transparent: HTMLCanvasElement
}

type InventorySlot = {
  name: string
  type: string
  power: number
  imageId: number
  description: string
  count: number
  raw: string
}

type BattleEnemy = {
  id: number
  x: number
  y: number
  hp: number
  maxHp: number
}

type BattleDuelState = {
  enemyId: number
  enemyMaxHp: number
  playerHitText: string
  previousPlayerHitText: string
  enemyHitText: string
  previousEnemyHitText: string
  actionText: string
  previousActionText: string
  allowInventory: boolean
}

type BattleState = {
  sourceMapName: string
  sourceTarget: {
    x: number
    y: number
  }
  sourceEventCode: number
  negativeTrigger: boolean
  terrainPersistent: boolean
  afterEventId: number
  exitDirections: Record<Direction, boolean>
  enemyAttack: number
  enemyDefense: number
  enemyDexterity: number
  enemyGoldFormula: string
  enemyExpFormula: string
  enemySprite: number
  enemySpeed: number
  enemyName: string
  enemyDescription: string
  enemyHpFormula: string
  enemyReward: string
  map: GameMap
  enemies: BattleEnemy[]
  stepCounter: number
  duel: BattleDuelState | null
}

type PlayerState = {
  x: number
  y: number
  facing: number
  avatar: number
  stepFrame: number
  name: string
}

type Runtime = {
  manifest: Manifest
  eventsById: Record<number, EventBlock>
  baseMaps: Record<string, GameMap>
  maps: Record<string, GameMap>
  mapName: string
  player: PlayerState
  stats: number[]
  inventory: Array<InventorySlot | null>
  almanach: string
  battle: BattleState | null
  gameStarted: boolean
  gameEnded: boolean
  status: string
}

type RuntimeSnapshot = {
  mapName: string
  player: PlayerState
  stats: number[]
  inventory: Array<InventorySlot | null>
  almanach: string
  battle: BattleState | null
  gameStarted: boolean
  gameEnded: boolean
  status: string
  maps: Record<string, GameMap>
}

type LoadedContent = {
  manifest: Manifest
  mapsByName: Record<string, GameMap>
  eventsById: Record<number, EventBlock>
}

type SaveRecord = {
  schemaVersion: number
  slotId: SaveSlotId
  savedAt: string
  playerName: string
  level: number
  mapName: string
  mapOriginalName: string
  runtime: RuntimeSnapshot
}

type SaveSlotSummary = {
  id: SaveSlotId
  label: string
  emptyText: string
  hasSave: boolean
  savedAt: string | null
  playerName: string | null
  level: number | null
  mapName: string | null
  mapOriginalName: string | null
}

type SellEntry = {
  slot: number
  item: InventorySlot
  price: number
}

type EventContext = {
  targetX: number
  targetY: number
  rawEventCode: number
  negativeTrigger: boolean
}

type OverlayState =
  | { type: 'message'; text: string; title?: string; blocking?: boolean }
  | { type: 'choice'; text: string; options: string[]; width?: number; fallbackText?: string }
  | { type: 'textInput'; text: string; fallbackText?: string }
  | { type: 'journal' }
  | { type: 'shopBuy'; text: string; items: InventorySlot[]; prices: number[]; notice?: string }
  | { type: 'shopSell'; text: string; allowedTypes: string[]; multiplier: number; notice?: string }
  | { type: 'mapView' }
  | { type: 'credits'; lines: string[] }
  | { type: 'inventory' }
  | { type: 'fade'; mode: 'out' | 'in' | 'hold'; durationMs?: number }

type ScreenState =
  | 'loading'
  | 'bootLogo'
  | 'bootLogo2'
  | 'menu'
  | 'newGame'
  | 'creditsMenu'
  | 'death'
  | 'game'

type PostEventMutation = {
  mapAfter: number
  infoAfter: number
  objectAfter: number
  expFormula: string
}

function getAssetUrl(path: string) {
  return `${import.meta.env.BASE_URL}${path}`
}

function normalizeMapName(mapName: string) {
  return mapName.toLowerCase()
}

function createTransparentSheet(image: HTMLImageElement) {
  const canvas = document.createElement('canvas')
  canvas.width = image.width
  canvas.height = image.height

  const context = canvas.getContext('2d')

  if (!context) {
    return canvas
  }

  context.imageSmoothingEnabled = false
  context.drawImage(image, 0, 0)

  const imageData = context.getImageData(0, 0, canvas.width, canvas.height)
  const { data } = imageData

  for (let index = 0; index < data.length; index += 4) {
    if (data[index] === 0 && data[index + 1] === 0 && data[index + 2] === 0) {
      data[index + 3] = 0
    }
  }

  context.putImageData(imageData, 0, 0)
  return canvas
}

function loadImageAsset(url: string) {
  return new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image()

    const cleanup = () => {
      image.onload = null
      image.onerror = null
    }

    image.onload = () => {
      cleanup()
      resolve(image)
    }

    image.onerror = () => {
      cleanup()
      reject(new Error(`could not load image ${url}`))
    }

    image.src = url

    if (image.complete && image.naturalWidth > 0 && image.naturalHeight > 0) {
      cleanup()
      resolve(image)
    }
  })
}

function cloneMap(map: GameMap): GameMap {
  return {
    ...map,
    start: { ...map.start },
    rows: map.rows.map((row) => row.map((cell) => ({ ...cell }))),
  }
}

function cloneMapRecord(record: Record<string, GameMap>) {
  const clone: Record<string, GameMap> = {}

  for (const [key, value] of Object.entries(record)) {
    clone[key] = cloneMap(value)
  }

  return clone
}

function createEmptyInventory() {
  return Array.from({ length: INVENTORY_SLOT_COUNT }, () => null) as Array<InventorySlot | null>
}

function cloneInventory(inventory: Array<InventorySlot | null>) {
  return inventory.map((item) => (item ? { ...item } : null)) as Array<InventorySlot | null>
}

function createEmptySaveSummaries(): SaveSlotSummary[] {
  return getSaveSlotDefinitions().map((slot) => ({
    id: slot.id,
    label: slot.label,
    emptyText: slot.emptyText,
    hasSave: false,
    savedAt: null,
    playerName: null,
    level: null,
    mapName: null,
    mapOriginalName: null,
  }))
}

function createRuntimeSnapshot(runtime: Runtime): RuntimeSnapshot {
  return {
    mapName: runtime.mapName,
    player: { ...runtime.player },
    stats: [...runtime.stats],
    inventory: cloneInventory(runtime.inventory),
    almanach: runtime.almanach,
    battle: runtime.battle
      ? {
          ...runtime.battle,
          sourceTarget: { ...runtime.battle.sourceTarget },
          exitDirections: { ...runtime.battle.exitDirections },
          map: cloneMap(runtime.battle.map),
          enemies: runtime.battle.enemies.map((enemy) => ({ ...enemy })),
          duel: runtime.battle.duel ? { ...runtime.battle.duel } : null,
        }
      : null,
    gameStarted: runtime.gameStarted,
    gameEnded: runtime.gameEnded,
    status: runtime.status,
    maps: cloneMapRecord(runtime.maps),
  }
}

function restoreRuntime(content: LoadedContent, snapshot: RuntimeSnapshot): Runtime {
  const ui = getUiText(getCurrentLanguage())
  const restoredMaps = cloneMapRecord(content.mapsByName)
  const savedMaps = snapshot.maps ?? {}

  for (const map of Object.values(savedMaps)) {
    if (map?.name) {
      restoredMaps[map.name] = cloneMap(map)
    }
  }

  const homeMap = restoredMaps['heimap.map'] ?? Object.values(restoredMaps)[0]
  const restoredMapName = restoredMaps[snapshot.mapName] ? snapshot.mapName : homeMap?.name ?? 'heimap.map'
  const stats = Array.from({ length: 11 }, (_, index) => snapshot.stats[index] ?? 0)
  const inventory = createEmptyInventory()

  for (let slot = 0; slot < INVENTORY_SLOT_COUNT; slot += 1) {
    const item = snapshot.inventory[slot]
    inventory[slot] = item ? { ...item } : null
  }

  return {
    manifest: content.manifest,
    eventsById: content.eventsById,
    baseMaps: content.mapsByName,
    maps: restoredMaps,
    mapName: restoredMapName,
    player: {
      x: snapshot.player.x,
      y: snapshot.player.y,
      facing: snapshot.player.facing,
      avatar: snapshot.player.avatar,
      stepFrame: snapshot.player.stepFrame,
      name: snapshot.player.name,
    },
    stats,
    inventory,
    almanach: snapshot.almanach ?? '',
    battle: snapshot.battle
      ? {
          ...snapshot.battle,
          sourceTarget: { ...snapshot.battle.sourceTarget },
          exitDirections: { ...snapshot.battle.exitDirections },
          map: cloneMap(snapshot.battle.map),
          enemies: snapshot.battle.enemies.map((enemy) => ({ ...enemy })),
          duel: snapshot.battle.duel ? { ...snapshot.battle.duel } : null,
        }
      : null,
    gameStarted: snapshot.gameStarted !== false,
    gameEnded: Boolean(snapshot.gameEnded),
    status: snapshot.status || ui.saveLoaded,
  }
}

function createSaveRecord(slotId: SaveSlotId, runtime: Runtime): SaveRecord {
  const activeMap = getActiveMap(runtime)

  return {
    schemaVersion: SAVE_SCHEMA_VERSION,
    slotId,
    savedAt: new Date().toISOString(),
    playerName: runtime.player.name,
    level: runtime.stats[4] ?? 1,
    mapName: getActiveMapName(runtime),
    mapOriginalName: activeMap.originalName,
    runtime: createRuntimeSnapshot(runtime),
  }
}

function summarizeSaveRecord(slotId: SaveSlotId, record: SaveRecord | null): SaveSlotSummary {
  const ui = getUiText(getCurrentLanguage())
  const definition = getSaveSlotDefinitions().find((slot) => slot.id === slotId)

  return {
    id: slotId,
    label: definition?.label ?? slotId,
    emptyText: definition?.emptyText ?? ui.emptySaveRecord,
    hasSave: Boolean(record),
    savedAt: record?.savedAt ?? null,
    playerName: record?.playerName ?? null,
    level: record?.level ?? null,
    mapName: record?.mapName ?? null,
    mapOriginalName: record?.mapOriginalName ?? null,
  }
}

function openSaveDatabase() {
  const ui = getUiText(getCurrentLanguage())

  return new Promise<IDBDatabase>((resolve, reject) => {
    if (typeof window === 'undefined' || !window.indexedDB) {
      reject(new Error(ui.indexedDbUnavailable))
      return
    }

    const request = window.indexedDB.open(SAVE_DATABASE_NAME, 1)

    request.onupgradeneeded = () => {
      const database = request.result

      if (!database.objectStoreNames.contains(SAVE_STORE_NAME)) {
        database.createObjectStore(SAVE_STORE_NAME, { keyPath: 'slotId' })
      }
    }

    request.onsuccess = () => {
      resolve(request.result)
    }

    request.onerror = () => {
      reject(request.error ?? new Error(ui.saveDbOpenFailure))
    }
  })
}

async function readSaveRecord(slotId: SaveSlotId) {
  const ui = getUiText(getCurrentLanguage())
  const database = await openSaveDatabase()

  return new Promise<SaveRecord | null>((resolve, reject) => {
    const transaction = database.transaction(SAVE_STORE_NAME, 'readonly')
    const store = transaction.objectStore(SAVE_STORE_NAME)
    const request = store.get(slotId)

    transaction.oncomplete = () => {
      database.close()
    }

    transaction.onabort = () => {
      database.close()
      reject(transaction.error ?? new Error(ui.saveLoadFailure))
    }

    request.onsuccess = () => {
      const record = (request.result as SaveRecord | undefined) ?? null
      resolve(record?.schemaVersion === SAVE_SCHEMA_VERSION ? record : null)
    }

    request.onerror = () => {
      reject(request.error ?? new Error(ui.saveReadFailure))
    }
  })
}

async function writeSaveRecord(record: SaveRecord) {
  const ui = getUiText(getCurrentLanguage())
  const database = await openSaveDatabase()

  return new Promise<void>((resolve, reject) => {
    const transaction = database.transaction(SAVE_STORE_NAME, 'readwrite')
    const store = transaction.objectStore(SAVE_STORE_NAME)
    store.put(record)

    transaction.oncomplete = () => {
      database.close()
      resolve()
    }

    transaction.onabort = () => {
      database.close()
      reject(transaction.error ?? new Error(ui.saveWriteFailure))
    }

    transaction.onerror = () => {
      database.close()
      reject(transaction.error ?? new Error(ui.saveWriteFailure))
    }
  })
}

async function readSavedGameSummary() {
  const record = await readSaveRecord('quicksave')
  return summarizeSaveRecord('quicksave', record)
}

function wrapDialogText(text: string, maxCharacters = DIALOG_LINE_LENGTH) {
  const normalized = text.replace(/\r/g, '')
  const lines: string[] = []

  for (const paragraph of normalized.split('\n')) {
    if (paragraph.trim() === '') {
      lines.push('')
      continue
    }

    let currentLine = ''

    for (const word of paragraph.trim().split(/\s+/)) {
      if (word.length > maxCharacters) {
        if (currentLine) {
          lines.push(currentLine)
          currentLine = ''
        }

        for (let index = 0; index < word.length; index += maxCharacters) {
          lines.push(word.slice(index, index + maxCharacters))
        }

        continue
      }

      const candidate = currentLine ? `${currentLine} ${word}` : word

      if (candidate.length > maxCharacters) {
        lines.push(currentLine)
        currentLine = word
      } else {
        currentLine = candidate
      }
    }

    if (currentLine) {
      lines.push(currentLine)
    }
  }

  return lines.length ? lines : ['']
}

function paginateDialogText(text: string, maxCharacters = DIALOG_LINE_LENGTH, linesPerPage = DIALOG_PAGE_LINES) {
  const lines = wrapDialogText(text, maxCharacters)
  const pages: string[] = []

  for (let index = 0; index < lines.length; index += linesPerPage) {
    pages.push(lines.slice(index, index + linesPerPage).join('\n'))
  }

  return pages.length ? pages : ['']
}

function SpriteIcon({
  tileId,
  spriteSheets,
  transparent = true,
  className = '',
}: {
  tileId: number
  spriteSheets: Map<number, SpriteSheetSet>
  transparent?: boolean
  className?: string
}) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  useEffect(() => {
    const canvas = canvasRef.current

    if (!canvas) {
      return
    }

    const context = canvas.getContext('2d')

    if (!context) {
      return
    }

    context.imageSmoothingEnabled = false
    context.clearRect(0, 0, TILE_SIZE, TILE_SIZE)

    if (tileId > 0) {
      drawTile(context, tileId, spriteSheets, 0, 0, 0, transparent)
    }
  }, [spriteSheets, tileId, transparent])

  return <canvas ref={canvasRef} width={TILE_SIZE} height={TILE_SIZE} className={className} aria-hidden="true" />
}

function AvatarPreview({
  avatarId,
  spriteSheets,
  frame,
  className = '',
}: {
  avatarId: number
  spriteSheets: Map<number, SpriteSheetSet>
  frame: number
  className?: string
}) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  useEffect(() => {
    const canvas = canvasRef.current

    if (!canvas) {
      return
    }

    const context = canvas.getContext('2d')

    if (!context) {
      return
    }

    context.imageSmoothingEnabled = false
    context.clearRect(0, 0, canvas.width, canvas.height)

    const playerSheet = spriteSheets.get(PLAYER_SHEET_INDEX)

    if (!playerSheet) {
      return
    }

    const sourceX = 80 + (frame % 4) * TILE_SIZE
    const sourceY = (avatarId - 1) * TILE_SIZE

    context.drawImage(playerSheet.transparent, sourceX, sourceY, TILE_SIZE, TILE_SIZE, 8, 2, 40, 40)
  }, [avatarId, frame, spriteSheets])

  return <canvas ref={canvasRef} width={56} height={44} className={className} aria-hidden="true" />
}

function BattleAvatarIcon({
  avatarId,
  spriteSheets,
  className = '',
}: {
  avatarId: number
  spriteSheets: Map<number, SpriteSheetSet>
  className?: string
}) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  useEffect(() => {
    const canvas = canvasRef.current

    if (!canvas) {
      return
    }

    const context = canvas.getContext('2d')

    if (!context) {
      return
    }

    context.imageSmoothingEnabled = false
    context.clearRect(0, 0, TILE_SIZE, TILE_SIZE)

    const playerSheet = spriteSheets.get(PLAYER_SHEET_INDEX)

    if (!playerSheet) {
      return
    }

    const sourceX = 80
    const sourceY = (avatarId - 1) * TILE_SIZE

    context.drawImage(playerSheet.transparent, sourceX, sourceY, TILE_SIZE, TILE_SIZE, 0, 0, TILE_SIZE, TILE_SIZE)
  }, [avatarId, spriteSheets])

  return <canvas ref={canvasRef} width={TILE_SIZE} height={TILE_SIZE} className={className} aria-hidden="true" />
}

function clampAnimatedTile(tileId: number, animationFrame: number) {
  const absolute = Math.abs(tileId)

  if (absolute <= 1279) {
    return absolute
  }

  const phaseOffset = (absolute - 1280) % 4
  const firstFrame = absolute - phaseOffset
  return firstFrame + ((phaseOffset + animationFrame) % 4)
}

function getMapCell(map: GameMap, x: number, y: number) {
  if (x < 1 || y < 1 || x > map.width || y > map.height) {
    return null
  }

  return map.rows[y - 1]?.[x - 1] ?? null
}

function setMapCell(map: GameMap, x: number, y: number, patch: Partial<MapCell>) {
  const cell = getMapCell(map, x, y)

  if (!cell) {
    return
  }

  Object.assign(cell, patch)
}

function isPassable(cell: MapCell | null) {
  return Boolean(cell && cell.terrain > 0 && cell.object <= 0)
}

function isEnemyWalkable(cell: MapCell | null) {
  return Boolean(cell && cell.terrain > 0 && cell.object === 0)
}

function drawTile(
  context: CanvasRenderingContext2D,
  tileId: number,
  sheets: Map<number, SpriteSheetSet>,
  screenX: number,
  screenY: number,
  animationFrame: number,
  transparent = false,
  size = TILE_SIZE,
) {
  const resolvedTile = clampAnimatedTile(tileId, animationFrame)
  const sheetIndex = Math.floor(resolvedTile / 160) + 1
  const sourceSheet = sheets.get(sheetIndex)

  if (!sourceSheet) {
    context.fillStyle = '#24170f'
    context.fillRect(screenX, screenY, size, size)
    return
  }

  const sourceX = Math.floor((resolvedTile % 160) / 10) * TILE_SIZE
  const sourceY = ((resolvedTile % 160) % 10) * TILE_SIZE
  const source = transparent ? sourceSheet.transparent : sourceSheet.opaque

  context.drawImage(source, sourceX, sourceY, TILE_SIZE, TILE_SIZE, screenX, screenY, size, size)
}

function randomInt(minInclusive: number, maxInclusive: number) {
  return Math.floor(Math.random() * (maxInclusive - minInclusive + 1)) + minInclusive
}

function calculateBattleDamage(attack: number, defense: number) {
  const damageAbsorb = (100 * defense) / Math.max(1, attack + defense)
  return Math.max(0, Math.floor(attack - attack * (damageAbsorb / 100) + Math.floor((Math.random() * attack) / 4 + 1) - attack / 8))
}

function diceNumber(formula: string) {
  const normalized = formula.trim()

  if (normalized === '') {
    return 0
  }

  const [left, right] = normalized.split('X')

  if (!right) {
    return Number.parseInt(left, 10) || 0
  }

  const base = Number.parseInt(left.trim(), 10) || 0
  const swing = Number.parseInt(right.trim(), 10) || 0

  return base + Math.floor(Math.random() * 2 * swing) - swing
}

function parseItemString(raw: string): InventorySlot | null {
  if (!raw) {
    return null
  }

  const delimiterIndex = raw.indexOf('=')

  if (delimiterIndex < 0 || delimiterIndex + 8 > raw.length) {
    return null
  }

  return {
    name: raw.slice(0, delimiterIndex),
    type: raw.slice(delimiterIndex + 1, delimiterIndex + 2),
    power: Number.parseInt(raw.slice(delimiterIndex + 2, delimiterIndex + 5), 10) || 0,
    imageId: Number.parseInt(raw.slice(delimiterIndex + 6, delimiterIndex + 9), 10) || 0,
    description: raw.slice(delimiterIndex + 10),
    count: 1,
    raw,
  }
}

function findItemSlot(runtime: Runtime, itemName: string) {
  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    if (runtime.inventory[slot]?.name === itemName) {
      return slot
    }
  }

  return 0
}

function countItem(runtime: Runtime, itemName: string) {
  const slot = findItemSlot(runtime, itemName)
  return slot > 0 ? runtime.inventory[slot]?.count ?? 0 : 0
}

function shiftInventoryDown(runtime: Runtime, fromSlot: number) {
  for (let slot = fromSlot; slot < MAX_BAG_SLOTS; slot += 1) {
    runtime.inventory[slot] = runtime.inventory[slot + 1]
  }

  runtime.inventory[MAX_BAG_SLOTS] = null
}

function removeInventoryAmount(runtime: Runtime, slot: number, amount: number) {
  const existing = runtime.inventory[slot]

  if (!existing) {
    return
  }

  if (existing.count - amount < 1) {
    runtime.inventory[slot] = null
    shiftInventoryDown(runtime, slot)
    return
  }

  existing.count -= amount
}

function addInventoryItem(runtime: Runtime, rawItem: string, amount: number) {
  const ui = getUiText(getCurrentLanguage())
  const parsed = parseItemString(rawItem)

  if (!parsed || amount <= 0) {
    return ''
  }

  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    if (runtime.inventory[slot]?.name === parsed.name) {
      runtime.inventory[slot]!.count += amount
      return ''
    }

    if (!runtime.inventory[slot]) {
      runtime.inventory[slot] = {
        ...parsed,
        count: amount,
      }
      return ''
    }
  }

  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    const entry = runtime.inventory[slot]

    if (entry?.type === '0' && entry.count === 1) {
      const dropped = entry.name
      runtime.inventory[slot] = { ...parsed, count: amount }
      return ui.bagFullDropped(dropped)
    }
  }

  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    const entry = runtime.inventory[slot]

    if (entry?.type === '0') {
      const dropped = entry.name
      runtime.inventory[slot] = { ...parsed, count: amount }
      return ui.bagFullDropped(dropped)
    }
  }

  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    const entry = runtime.inventory[slot]

    if (entry && entry.type !== 'U') {
      const dropped = entry.name
      runtime.inventory[slot] = { ...parsed, count: amount }
      return ui.bagFullDropped(dropped)
    }
  }

  return ui.noBagSpace(parsed.name)
}

function getEquipmentSlotByType(itemType: string) {
  switch (itemType) {
    case 'H':
      return 21
    case 'W':
      return 22
    case 'A':
      return 23
    case 'S':
      return 24
    case 'B':
      return 25
    default:
      return 0
  }
}

function getAttributeSlotByType(itemType: string) {
  switch (itemType) {
    case 'W':
      return 5
    case 'A':
    case 'S':
      return 6
    case 'H':
    case 'B':
      return 10
    default:
      return 0
  }
}

function equipInventoryItem(runtime: Runtime, bagSlot: number) {
  const ui = getUiText(getCurrentLanguage())
  const selected = runtime.inventory[bagSlot]

  if (!selected) {
    return ui.emptySlot
  }

  const equipmentSlot = getEquipmentSlotByType(selected.type)
  const attributeSlot = getAttributeSlotByType(selected.type)

  if (equipmentSlot === 0 || attributeSlot === 0) {
    return ui.cannotEquip
  }

  const previous = runtime.inventory[equipmentSlot]
  runtime.stats[attributeSlot] += selected.power - (previous?.power ?? 0)

  runtime.inventory[equipmentSlot] = {
    ...selected,
    count: 1,
  }

  if (previous) {
    runtime.inventory[bagSlot] = { ...previous, count: 1 }
  } else {
    runtime.inventory[bagSlot] = null
    shiftInventoryDown(runtime, bagSlot)
  }

  return ui.equippedItem(selected.name)
}

function getFirstFilledBagSlot(runtime: Runtime) {
  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    if (runtime.inventory[slot]) {
      return slot
    }
  }

  return 1
}

function getInventoryItems(runtime: Runtime) {
  const items: Array<{ slot: number; item: InventorySlot }> = []

  for (let slot = 1; slot <= MAX_BAG_SLOTS; slot += 1) {
    const item = runtime.inventory[slot]

    if (item) {
      items.push({ slot, item })
    }
  }

  return items
}

function wrapIndex(index: number, length: number) {
  if (length <= 0) {
    return 0
  }

  return ((index % length) + length) % length
}

function getShopCarouselIndices(length: number, selectedIndex: number) {
  if (length <= 0) {
    return []
  }

  if (length <= 3) {
    return Array.from({ length }, (_, index) => index)
  }

  return [-1, 0, 1].map((offset) => wrapIndex(selectedIndex + offset, length))
}

function formatShopItemName(item: InventorySlot) {
  if (item.type === 'W' || item.type === 'A' || item.type === 'S' || item.type === 'H' || item.type === 'B') {
    return `${item.name} +${item.power}`
  }

  return item.name
}

function getSellEntries(runtime: Runtime | null, overlay: OverlayState | null): SellEntry[] {
  if (!runtime || overlay?.type !== 'shopSell') {
    return []
  }

  return getInventoryItems(runtime)
    .filter(({ item }) => overlay.allowedTypes.includes(item.type))
    .map(({ slot, item }) => ({
      slot,
      item,
      price:
        item.type === 'E'
          ? TOOL_VALUE * item.count * overlay.multiplier
          : item.power * item.count * overlay.multiplier,
    }))
}

function getActiveMap(runtime: Runtime) {
  return runtime.battle ? runtime.battle.map : runtime.maps[runtime.mapName]
}

function getActiveMapName(runtime: Runtime) {
  return runtime.battle ? runtime.battle.map.name : runtime.mapName
}

function createNewRuntime(content: LoadedContent, name: string, avatar: number): Runtime {
  const ui = getUiText(getCurrentLanguage())
  const stats = Array.from({ length: 11 }, () => 0)
  stats[1] = 20
  stats[2] = 20
  stats[3] = 0
  stats[4] = 1
  stats[5] = 10
  stats[6] = 10
  stats[7] = 0
  stats[10] = 5

  const homeMap = content.mapsByName['heimap.map']

  return {
    manifest: content.manifest,
    eventsById: content.eventsById,
    baseMaps: content.mapsByName,
    maps: cloneMapRecord(content.mapsByName),
    mapName: homeMap ? homeMap.name : 'heimap.map',
    player: {
      x: homeMap?.start.x ?? 1,
      y: homeMap?.start.y ?? 1,
      facing: 1,
      avatar,
      stepFrame: 0,
      name,
    },
    stats,
    inventory: createEmptyInventory(),
    almanach: '',
    battle: null,
    gameStarted: true,
    gameEnded: false,
    status: ui.runtimeReady,
  }
}

function createCursor(lines: string[]) {
  let index = 1

  return {
    readString() {
      const value = lines[index] ?? ''
      index += 1
      return value
    },
    readInt() {
      const value = lines[index] ?? ''
      index += 1
      const parsed = Number.parseInt(value, 10)
      return Number.isNaN(parsed) ? 0 : parsed
    },
  }
}

function createPostEventMutation(cursor: ReturnType<typeof createCursor>): PostEventMutation {
  return {
    mapAfter: cursor.readInt(),
    infoAfter: cursor.readInt(),
    objectAfter: cursor.readInt(),
    expFormula: cursor.readString(),
  }
}

function chooseEnemyStep(enemy: BattleEnemy, player: PlayerState, map: GameMap) {
  const dx = player.x - enemy.x
  const dy = player.y - enemy.y
  const candidates: Array<{ x: number; y: number }> = []

  const horizontalFirst = Math.abs(dx) >= Math.abs(dy)
  const primaryX = dx === 0 ? 0 : dx > 0 ? 1 : -1
  const primaryY = dy === 0 ? 0 : dy > 0 ? 1 : -1

  if (horizontalFirst) {
    if (primaryX !== 0) {
      candidates.push({ x: enemy.x + primaryX, y: enemy.y })
    }
    if (primaryY !== 0) {
      candidates.push({ x: enemy.x, y: enemy.y + primaryY })
    }
  } else {
    if (primaryY !== 0) {
      candidates.push({ x: enemy.x, y: enemy.y + primaryY })
    }
    if (primaryX !== 0) {
      candidates.push({ x: enemy.x + primaryX, y: enemy.y })
    }
  }

  for (const candidate of candidates) {
    if (isEnemyWalkable(getMapCell(map, candidate.x, candidate.y))) {
      return candidate
    }
  }

  return { x: enemy.x, y: enemy.y }
}

function findBattleEnemyById(battle: BattleState, enemyId: number) {
  return battle.enemies.find((enemy) => enemy.id === enemyId) ?? null
}

function setBattleDuelAction(duel: BattleDuelState, actionText: string) {
  duel.previousActionText = duel.actionText
  duel.actionText = actionText
}

function App() {
  const language = readLanguageFromSearch(typeof window !== 'undefined' ? window.location.search : '')
  const ui = getUiText(language)
  const searchParams = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : new URLSearchParams()
  const runtimeRef = useRef<Runtime | null>(null)
  const contentRef = useRef<LoadedContent | null>(null)
  const overlayResolverRef = useRef<((value: unknown) => void) | null>(null)
  const overlayRef = useRef<OverlayState | null>(null)
  const screenRef = useRef<ScreenState>('loading')
  const eventDepthRef = useRef(0)
  const gameInteractionLockRef = useRef(false)
  const battleAdvanceStepCountRef = useRef(0)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const mapCanvasRef = useRef<HTMLCanvasElement | null>(null)
  const gameStageRef = useRef<HTMLDivElement | null>(null)
  const inlineDialogPanelRef = useRef<HTMLElement | null>(null)
  const inlineTextInputRef = useRef<HTMLInputElement | null>(null)
  const newGameNameInputRef = useRef<HTMLInputElement | null>(null)
  const newGameStartButtonRef = useRef<HTMLButtonElement | null>(null)
  const newGameCloseButtonRef = useRef<HTMLButtonElement | null>(null)
  const newGameAvatarButtonRefs = useRef<Array<HTMLButtonElement | null>>([])
  const bodyOverflowRef = useRef<string | null>(null)
  const initialMapRevealPendingRef = useRef(false)
  const retainedInlineDialogTextRef = useRef('')

  const [renderVersion, setRenderVersion] = useState(0)
  const [loadingMessage, setLoadingMessage] = useState<string>(ui.loadingContent)
  const [isContentReady, setIsContentReady] = useState(false)
  const [overlay, setOverlay] = useState<OverlayState | null>(null)
  const [fullscreenSupported, setFullscreenSupported] = useState(false)
  const [isViewportMaximized, setIsViewportMaximized] = useState(false)
  const [spriteSheets, setSpriteSheets] = useState<Map<number, SpriteSheetSet>>(new Map())
  const [startName, setStartName] = useState<string>(ui.defaultPlayerName)
  const [startAvatar, setStartAvatar] = useState(1)
  const [textInputValue, setTextInputValue] = useState('')
  const [inventorySelection, setInventorySelection] = useState(1)
  const [shopSelection, setShopSelection] = useState(0)
  const [animationTick, setAnimationTick] = useState(0)
  const [frontAnimationTick, setFrontAnimationTick] = useState(0)
  const [debugMapSelection, setDebugMapSelection] = useState('')
  const [dialogLineLength, setDialogLineLength] = useState(DIALOG_LINE_LENGTH)
  const [dialogPageIndex, setDialogPageIndex] = useState(0)
  const [dialogVisibleCharacterCount, setDialogVisibleCharacterCount] = useState(0)
  const [dialogChoiceSelection, setDialogChoiceSelection] = useState(1)
  const [menuSelection, setMenuSelection] = useState(0)
  const [screen, setScreen] = useState<ScreenState>('loading')
  const [saveSlots, setSaveSlots] = useState<SaveSlotSummary[]>(() => createEmptySaveSummaries())
  const [saveScreenMessage, setSaveScreenMessage] = useState('')
  const [hideSceneUntilReveal, setHideSceneUntilReveal] = useState(false)
  const [viewportState, setViewportState] = useState<ViewportState>(() => readViewportState())
  const [isGameInteractionLocked, setIsGameInteractionLocked] = useState(false)

  overlayRef.current = overlay
  screenRef.current = screen

  const runtime = runtimeRef.current
  const activeMap = runtime ? getActiveMap(runtime) : null
  const activeBattle = runtime?.battle ?? null
  const battleDuel = activeBattle?.duel ?? null
  const battleDuelEnemy = battleDuel && activeBattle ? findBattleEnemyById(activeBattle, battleDuel.enemyId) : null
  const hasActiveRun = Boolean(runtime?.gameStarted && !runtime?.gameEnded)
  const savedGameSummary = saveSlots[0] ?? null
  const isDebugMode = searchParams.has('debug')
  const isBlockingMessageOverlay = overlay?.type === 'message' && overlay.blocking !== false
  const isAmbientMessageOverlay = overlay?.type === 'message' && overlay.blocking === false
  const isMobileViewport = viewportState.coarsePointer && Math.min(viewportState.width, viewportState.height) <= 900
  const requiresLandscapeMode = isMobileViewport && viewportState.height > viewportState.width
  const menuEntries: Array<{ label: string; variant: 'primary' | 'ghost'; action: () => void }> = [
    ...(hasActiveRun
      ? [
          {
            label: ui.menuResumeGame,
            variant: 'ghost' as const,
            action: () => resumeGame(),
          },
        ]
      : []),
    {
      label: ui.menuLoadGame,
      variant: 'ghost',
      action: () => {
        void loadSavedGameFromMenu()
      },
    },
    {
      label: ui.menuNewGame,
      variant: 'primary',
      action: () => setScreen('newGame'),
    },
    {
      label: ui.menuCredits,
      variant: 'ghost',
      action: () => setScreen('creditsMenu'),
    },
    {
      label: ui.menuQuit,
      variant: 'ghost',
      action: () => openMainMenu(true),
    },
  ]

  const refresh = () => {
    setRenderVersion((previous) => previous + 1)
  }

  async function runLockedGameInteraction(task: () => Promise<void>) {
    if (gameInteractionLockRef.current) {
      return
    }

    gameInteractionLockRef.current = true
    setIsGameInteractionLocked(true)

    try {
      await task()
    } finally {
      gameInteractionLockRef.current = false
      setIsGameInteractionLocked(false)
    }
  }

  const canControl = Boolean(
    screen === 'game' &&
      runtime?.gameStarted &&
      !runtime?.gameEnded &&
      !runtime?.battle?.duel &&
      (!overlay || isAmbientMessageOverlay) &&
      eventDepthRef.current === 0 &&
      !isGameInteractionLocked,
  )
  const inlineDialogOverlay =
    overlay?.type === 'message' || overlay?.type === 'choice' || overlay?.type === 'textInput' ? overlay : null
  const inlineScreenOverlay =
    overlay?.type === 'inventory' ||
    overlay?.type === 'journal' ||
    overlay?.type === 'shopBuy' ||
    overlay?.type === 'shopSell' ||
    overlay?.type === 'mapView' ||
    overlay?.type === 'credits'
      ? overlay
      : null
  const modalOverlay = overlay && overlay !== inlineDialogOverlay && overlay !== inlineScreenOverlay ? overlay : null
  const showMobileControls = screen === 'game' && isMobileViewport && !requiresLandscapeMode
  const mobileControlButtonsDisabled = modalOverlay?.type === 'fade'
  const messagePages = inlineDialogOverlay?.type === 'message' ? paginateDialogText(inlineDialogOverlay.text, dialogLineLength) : []
  const activeMessagePage = messagePages[dialogPageIndex] ?? ''
  const usesRetainedInlineDialogText = Boolean(
    (inlineDialogOverlay?.type === 'choice' || inlineDialogOverlay?.type === 'textInput') &&
      inlineDialogOverlay.text.trim() === '' &&
      inlineDialogOverlay.fallbackText,
  )
  const inlinePromptText =
    inlineDialogOverlay?.type === 'choice' || inlineDialogOverlay?.type === 'textInput'
      ? usesRetainedInlineDialogText
        ? (inlineDialogOverlay.fallbackText ?? '')
        : wrapDialogText(inlineDialogOverlay.text, dialogLineLength).join('\n')
      : ''
  const inlineDialogText =
    inlineDialogOverlay?.type === 'message'
      ? activeMessagePage
      : inlineDialogOverlay?.type === 'choice' || inlineDialogOverlay?.type === 'textInput'
        ? inlinePromptText
        : ''
  const dialogTypingKey =
    inlineDialogOverlay?.type === 'message'
      ? `message:${inlineDialogOverlay.text}:${dialogPageIndex}`
      : inlineDialogOverlay?.type === 'choice'
        ? `choice:${inlineDialogOverlay.text}`
        : inlineDialogOverlay?.type === 'textInput'
          ? `textInput:${inlineDialogOverlay.text}`
          : ''
  const inlineDialogLineCount = Math.max(1, inlineDialogText.split('\n').length)
  const inlineDialogHeightRem = 1.8 + inlineDialogLineCount * 1.55
  const visibleInlineDialogText = inlineDialogText.slice(0, dialogVisibleCharacterCount)
  const isInlineDialogTextFullyVisible = dialogVisibleCharacterCount >= inlineDialogText.length
  const isLastMessagePage = inlineDialogOverlay?.type === 'message' && dialogPageIndex >= messagePages.length - 1
  const battleActionLines = battleDuel ? wrapDialogText(battleDuel.actionText, 52).slice(0, 2) : []
  const battlePreviousActionLines =
    battleDuel?.previousActionText ? wrapDialogText(battleDuel.previousActionText, 52).slice(0, 1) : []
  const battleDescriptionLines =
    battleDuel && activeBattle ? wrapDialogText(activeBattle.enemyDescription, 46).slice(0, 1) : []
  const battlePlayerHpRatio = runtime && runtime.stats[2] > 0 ? Math.max(0, Math.min(1, runtime.stats[1] / runtime.stats[2])) : 0
  const battleEnemyHpRatio =
    battleDuelEnemy && battleDuel && battleDuel.enemyMaxHp > 0 ? Math.max(0, Math.min(1, battleDuelEnemy.hp / battleDuel.enemyMaxHp)) : 0
  const dialogPanelStyle = {
    height: `${inlineDialogHeightRem}rem`,
  }
  const choiceBoxStyle =
    inlineDialogOverlay?.type === 'choice'
      ? {
          width: `${Math.max(42, Math.min(100, ((inlineDialogOverlay.width ?? 220) / CANVAS_WIDTH) * 100))}%`,
          bottom: `calc(${inlineDialogHeightRem}rem + 0.4rem)`,
        }
      : undefined

  function focusNewGameAvatarByIndex(index: number) {
    const avatar = ui.avatarOptions[index]

    if (!avatar) {
      return
    }

    setStartAvatar(avatar.id)
    window.requestAnimationFrame(() => {
      newGameAvatarButtonRefs.current[index]?.focus()
    })
  }

  function focusSelectedNewGameAvatar() {
    const selectedIndex = ui.avatarOptions.findIndex((avatar) => avatar.id === startAvatar)
    focusNewGameAvatarByIndex(selectedIndex >= 0 ? selectedIndex : 0)
  }

  function measureDialogLineLength() {
    const panel = inlineDialogPanelRef.current ?? gameStageRef.current

    if (!panel) {
      return
    }

    const textElement = panel.querySelector('.inline-dialog-text') as HTMLElement | null
    const measurementTarget = textElement ?? panel
    const computedStyle = window.getComputedStyle(measurementTarget)
    const availableWidth = measurementTarget.clientWidth

    if (availableWidth <= 0) {
      return
    }

    const canvas = document.createElement('canvas')
    const context = canvas.getContext('2d')

    if (!context) {
      return
    }

    context.font = `${computedStyle.fontStyle} ${computedStyle.fontVariant} ${computedStyle.fontWeight} ${computedStyle.fontSize} ${computedStyle.fontFamily}`
    const characterWidth = context.measureText('M'.repeat(64)).width / 64

    if (characterWidth <= 0) {
      return
    }

    setDialogLineLength(Math.max(24, Math.floor(availableWidth / characterWidth) - 1))
  }

  useEffect(() => {
    let cancelled = false

    async function loadContent() {
      try {
        const manifestResponse = await fetch(getAssetUrl('game-data/manifest.json'))

        if (!manifestResponse.ok) {
          throw new Error(`manifest request failed with ${manifestResponse.status}`)
        }

        const manifest = (await manifestResponse.json()) as Manifest
        const eventsResponse = await fetch(getAssetUrl(`game-data/${getEventFileName(language)}`))

        if (!eventsResponse.ok) {
          throw new Error(`events request failed with ${eventsResponse.status}`)
        }

        const events = (await eventsResponse.json()) as EventBlock[]
        const maps = await Promise.all(
          manifest.maps.map(async (entry) => {
            const response = await fetch(getAssetUrl(`game-data/maps/${entry.name}.json`))

            if (!response.ok) {
              throw new Error(`map request for ${entry.name} failed with ${response.status}`)
            }

            return (await response.json()) as GameMap
          }),
        )

        if (cancelled) {
          return
        }

        const mapsByName = Object.fromEntries(maps.map((map) => [map.name, map])) as Record<string, GameMap>
        const eventsById = Object.fromEntries(events.map((event) => [event.id, event])) as Record<number, EventBlock>

        contentRef.current = {
          manifest,
          mapsByName,
          eventsById,
        }

        setIsContentReady(true)
        setLoadingMessage(ui.loadingSuccess(manifest.counts.maps, manifest.counts.eventBlocks))
      } catch (error) {
        const message = error instanceof Error ? error.message : ui.unknownError
        setLoadingMessage(ui.loadingFailure(message))
      }
    }

    void loadContent()

    return () => {
      cancelled = true
    }
  }, [language, ui])

  useEffect(() => {
    let cancelled = false

    async function loadSprites() {
      const spritePromises = TILE_SHEET_FILES.map(async (fileName, index) => {
        if (index === 0 || fileName === '') {
          return null
        }

        const image = await loadImageAsset(getAssetUrl(`game-assets/${fileName}`))
        return [
          index,
          {
            opaque: image,
            transparent: createTransparentSheet(image),
          },
        ] as const
      })

      try {
        const resolved = (await Promise.all(spritePromises)).filter(
          (entry): entry is readonly [number, SpriteSheetSet] => entry !== null,
        )

        if (cancelled) {
          return
        }

        setSpriteSheets(new Map(resolved))
      } catch (error) {
        const message = error instanceof Error ? error.message : 'unknown error'
        setLoadingMessage(`Sprite loading failed: ${message}`)
      }
    }

    void loadSprites()

    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (screen === 'menu') {
      setMenuSelection(0)
    }
  }, [screen, hasActiveRun])

  useEffect(() => {
    let cancelled = false

    async function loadSaveSummary() {
      try {
        const summary = await readSavedGameSummary()

        if (!cancelled) {
          setSaveSlots([summary])
        }
      } catch (error) {
        if (cancelled) {
          return
        }

        const message = error instanceof Error ? error.message : ui.unknownStorageError
        setSaveScreenMessage(message)
        setSaveSlots(createEmptySaveSummaries())
      }
    }

    void loadSaveSummary()

    return () => {
      cancelled = true
    }
  }, [ui])

  useEffect(() => {
    if (typeof document === 'undefined') {
      return
    }

    document.documentElement.lang = getDocumentLanguage(language)
  }, [language])

  useEffect(() => {
    const updateViewportState = () => {
      setViewportState(readViewportState())
    }

    updateViewportState()
    window.addEventListener('resize', updateViewportState)

    return () => {
      window.removeEventListener('resize', updateViewportState)
    }
  }, [])

  useEffect(() => {
    if (!isMobileViewport || typeof window === 'undefined') {
      return
    }

    const orientation = window.screen?.orientation as (ScreenOrientation & {
      lock?: (orientation: 'landscape') => Promise<void>
    }) | null

    if (!orientation || typeof orientation.lock !== 'function') {
      return
    }

    orientation.lock('landscape').catch(() => {
      // Most mobile browsers only allow locking during fullscreen or installed app contexts.
    })
  }, [isMobileViewport])

  useEffect(() => {
    if (!inlineDialogOverlay) {
      setDialogLineLength(DIALOG_LINE_LENGTH)
      return
    }

    const measure = () => {
      window.requestAnimationFrame(() => {
        measureDialogLineLength()
      })
    }

    measure()
    window.addEventListener('resize', measure)

    return () => {
      window.removeEventListener('resize', measure)
    }
  }, [inlineDialogOverlay, isViewportMaximized])

  useEffect(() => {
    if (screen !== 'newGame') {
      return
    }

    const focusId = window.requestAnimationFrame(() => {
      newGameNameInputRef.current?.focus()
      newGameNameInputRef.current?.select()
    })

    return () => {
      window.cancelAnimationFrame(focusId)
    }
  }, [screen])

  useEffect(() => {
    setFullscreenSupported(typeof document !== 'undefined' && typeof document.documentElement.requestFullscreen === 'function')
  }, [])

  useEffect(() => {
    if (typeof document === 'undefined') {
      return
    }

    if (bodyOverflowRef.current === null) {
      bodyOverflowRef.current = document.body.style.overflow
    }

    if (isViewportMaximized) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = bodyOverflowRef.current
    }

    return () => {
      document.body.style.overflow = bodyOverflowRef.current ?? ''
    }
  }, [isViewportMaximized])

  useEffect(() => {
    // The DOS game advances ambient animated tiles whenever TIMER increases by more than 0.1 seconds.
    const intervalId = window.setInterval(() => {
      if (runtimeRef.current?.gameStarted) {
        setAnimationTick((previous) => (previous + 1) % 4)
      }
    }, 100)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [])

  useEffect(() => {
    if (screen !== 'newGame') {
      return
    }

    const intervalId = window.setInterval(() => {
      setFrontAnimationTick((previous) => (previous + 1) % 4)
    }, 140)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [screen])

  useEffect(() => {
    if (screen !== 'loading') {
      return
    }

    if (!isContentReady) {
      return
    }

    setScreen('bootLogo')
  }, [isContentReady, screen])

  useEffect(() => {
    if (screen !== 'bootLogo' && screen !== 'bootLogo2') {
      return
    }

    const timeoutId = window.setTimeout(
      () => {
        setScreen(screen === 'bootLogo' ? 'bootLogo2' : 'menu')
      },
      screen === 'bootLogo' ? 2200 : 2800,
    )

    return () => {
      window.clearTimeout(timeoutId)
    }
  }, [screen])

  useEffect(() => {
    if (activeMap?.name) {
      setDebugMapSelection(activeMap.name)
    }
  }, [activeMap?.name])

  useEffect(() => {
    if (inlineDialogText) {
      retainedInlineDialogTextRef.current = inlineDialogText
    }
  }, [inlineDialogText])

  useEffect(() => {
    if (!dialogTypingKey) {
      setDialogVisibleCharacterCount(0)
      return
    }

    if (usesRetainedInlineDialogText) {
      setDialogVisibleCharacterCount(inlineDialogText.length)
      return
    }

    setDialogVisibleCharacterCount(0)
  }, [dialogTypingKey, inlineDialogText.length, usesRetainedInlineDialogText])

  useEffect(() => {
    if (!inlineDialogText || usesRetainedInlineDialogText) {
      return
    }

    const intervalId = window.setInterval(() => {
      setDialogVisibleCharacterCount((previous) => {
        if (previous >= inlineDialogText.length) {
          window.clearInterval(intervalId)
          return previous
        }

        return previous + 1
      })
    }, DIALOG_CHARACTER_DELAY_MS)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [dialogTypingKey, inlineDialogText, usesRetainedInlineDialogText])

  useEffect(() => {
    if (overlay?.type === 'choice') {
      setDialogChoiceSelection(1)
    }

    if (overlay?.type === 'textInput' && isInlineDialogTextFullyVisible) {
      const focusId = window.requestAnimationFrame(() => {
        inlineTextInputRef.current?.focus()
      })

      return () => {
        window.cancelAnimationFrame(focusId)
      }
    }

    return undefined
  }, [isInlineDialogTextFullyVisible, overlay])

  useEffect(() => {
    if (screen === 'game' || overlay?.type !== 'message' || overlay.blocking !== false) {
      return
    }

    setOverlay(null)
    setDialogPageIndex(0)
  }, [overlay, screen])

  const triggerDeath = useEffectEvent(() => {
    void handleDeath()
  })

  useEffect(() => {
    const activeRuntime = runtimeRef.current

    if (screen !== 'game' || !activeRuntime || activeRuntime.gameEnded) {
      return
    }

    if (activeRuntime.stats[1] <= 0) {
      triggerDeath()
    }
  }, [overlay, renderVersion, screen])

  useEffect(() => {
    const canvas = canvasRef.current
    const activeRuntime = runtimeRef.current
    const map = activeRuntime ? getActiveMap(activeRuntime) : null

    if (!canvas || !activeRuntime || !map) {
      return
    }

    const context = canvas.getContext('2d')

    if (!context) {
      return
    }

    context.imageSmoothingEnabled = false
    context.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)
    context.fillStyle = '#080604'
    context.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)

    if (hideSceneUntilReveal) {
      context.strokeStyle = '#ead7a0'
      context.lineWidth = 2
      context.strokeRect(1, 1, CANVAS_WIDTH - 2, CANVAS_HEIGHT - 2)
      return
    }

    const animationFrame = animationTick % 4

    for (let offsetX = -VIEW_RADIUS_X; offsetX <= VIEW_RADIUS_X; offsetX += 1) {
      for (let offsetY = -VIEW_RADIUS_Y; offsetY <= VIEW_RADIUS_Y; offsetY += 1) {
        const worldX = activeRuntime.player.x + offsetX
        const worldY = activeRuntime.player.y + offsetY
        const cell = getMapCell(map, worldX, worldY)
        const terrainTile = cell?.terrain ?? map.outsideTile
        const objectTile = cell?.object ?? 0
        const screenX = (offsetX + VIEW_RADIUS_X) * TILE_SIZE - 10
        const screenY = (offsetY + VIEW_RADIUS_Y) * TILE_SIZE - 10

        drawTile(context, terrainTile, spriteSheets, screenX, screenY, animationFrame, false)

        if (objectTile !== 0) {
          drawTile(context, objectTile, spriteSheets, screenX, screenY, animationFrame, true)
        }
      }
    }

    const playerSheet = spriteSheets.get(PLAYER_SHEET_INDEX)

    if (playerSheet) {
      const sourceX = activeRuntime.player.facing * 80 + activeRuntime.player.stepFrame * TILE_SIZE
      const sourceY = (activeRuntime.player.avatar - 1) * TILE_SIZE

      context.drawImage(playerSheet.transparent, sourceX, sourceY, TILE_SIZE, TILE_SIZE, 150, 90, TILE_SIZE, TILE_SIZE)
    } else {
      context.fillStyle = '#f0e2bd'
      context.fillRect(154, 94, 12, 12)
    }

    context.strokeStyle = '#ead7a0'
    context.lineWidth = 2
    context.strokeRect(1, 1, CANVAS_WIDTH - 2, CANVAS_HEIGHT - 2)
  }, [animationTick, hideSceneUntilReveal, renderVersion, spriteSheets])

  useEffect(() => {
    if (overlay?.type !== 'mapView') {
      return
    }

    const activeRuntime = runtimeRef.current
    const map = activeRuntime ? getActiveMap(activeRuntime) : null
    const canvas = mapCanvasRef.current

    if (!activeRuntime || !map || !canvas) {
      return
    }

    const scale = Math.max(2, Math.min(8, Math.floor(520 / Math.max(map.width, map.height))))
    canvas.width = map.width * scale
    canvas.height = map.height * scale

    const context = canvas.getContext('2d')

    if (!context) {
      return
    }

    context.imageSmoothingEnabled = false
    context.clearRect(0, 0, canvas.width, canvas.height)

    for (let y = 1; y <= map.height; y += 1) {
      for (let x = 1; x <= map.width; x += 1) {
        const cell = getMapCell(map, x, y)

        if (!cell) {
          continue
        }

        drawTile(context, cell.terrain, spriteSheets, (x - 1) * scale, (y - 1) * scale, 0, false, scale)

        if (cell.object !== 0) {
          drawTile(context, cell.object, spriteSheets, (x - 1) * scale, (y - 1) * scale, 0, true, scale)
        }
      }
    }

    context.strokeStyle = '#ffffff'
    context.lineWidth = 1
    context.strokeRect((activeRuntime.player.x - 1) * scale, (activeRuntime.player.y - 1) * scale, scale, scale)
  }, [overlay, renderVersion, spriteSheets])

  function handleDirectionalInput(direction: Direction) {
    if (screen !== 'game') {
      return
    }

    if (revealInlineDialogTextFromButtonPress()) {
      return
    }

    if (overlay?.type === 'message') {
      if (overlay.blocking !== false) {
        const closed = advanceMessageOverlay()

        if (closed) {
          scheduleMoveAfterMessageDismiss(direction)
        }

        return
      }

      dismissAmbientMessageOverlay()

      if (!canControl || gameInteractionLockRef.current) {
        return
      }

      void runLockedGameInteraction(() => movePlayer(direction))
      return
    }

    if ((overlay?.type === 'choice' || overlay?.type === 'textInput') && !isInlineDialogTextFullyVisible) {
      return
    }

    if (overlay?.type === 'choice') {
      if (direction === 'up' || direction === 'left') {
        setDialogChoiceSelection((previous) => (previous > 1 ? previous - 1 : overlay.options.length))
      } else {
        setDialogChoiceSelection((previous) => (previous < overlay.options.length ? previous + 1 : 1))
      }
      return
    }

    if (overlay?.type === 'inventory') {
      moveInventorySelection(direction)
      return
    }

    if (overlay?.type === 'shopBuy') {
      moveShopSelection(direction === 'left' || direction === 'up' ? -1 : 1, overlay.items.length)
      return
    }

    if (overlay?.type === 'shopSell') {
      const sellEntries = getSellEntries(runtimeRef.current, overlay)
      moveShopSelection(direction === 'left' || direction === 'up' ? -1 : 1, sellEntries.length)
      return
    }

    if (overlay?.type) {
      return
    }

    if (!canControl || gameInteractionLockRef.current) {
      return
    }

    void runLockedGameInteraction(() => movePlayer(direction))
  }

  function handleConfirmInput(options?: { allowTextSubmit?: boolean }) {
    const allowTextSubmit = options?.allowTextSubmit ?? false

    if (screen !== 'game') {
      return
    }

    if (isBlockingMessageOverlay) {
      advanceMessageOverlay()
      return
    }

    if (isAmbientMessageOverlay && !isInlineDialogTextFullyVisible) {
      revealInlineDialogText()
      return
    }

    if (isAmbientMessageOverlay) {
      dismissAmbientMessageOverlay()
      return
    }

    if ((overlay?.type === 'choice' || overlay?.type === 'textInput') && !isInlineDialogTextFullyVisible) {
      revealInlineDialogText()
      return
    }

    if (overlay?.type === 'choice') {
      resolveOverlay(dialogChoiceSelection)
      return
    }

    if (overlay?.type === 'textInput') {
      if (allowTextSubmit) {
        resolveOverlay(textInputValue.toUpperCase())
      }
      return
    }

    if (overlay?.type === 'inventory') {
      triggerInventorySelection()
      return
    }

    if (overlay?.type === 'journal') {
      closeOverlay()
      return
    }

    if (overlay?.type === 'shopBuy') {
      if (overlay.items.length > 0) {
        resolveOverlay(wrapIndex(shopSelection, overlay.items.length))
      }
      return
    }

    if (overlay?.type === 'shopSell') {
      const sellEntries = getSellEntries(runtimeRef.current, overlay)

      if (sellEntries.length > 0) {
        resolveOverlay(sellEntries[wrapIndex(shopSelection, sellEntries.length)]?.slot ?? null)
      }
      return
    }

    if (overlay?.type === 'mapView' || overlay?.type === 'credits') {
      resolveOverlay(undefined)
      return
    }

    if (runtimeRef.current?.battle?.duel?.allowInventory) {
      battleAdvanceStepCountRef.current += 1
      return
    }

    if (!canControl || gameInteractionLockRef.current) {
      return
    }

    void runLockedGameInteraction(() => triggerAction())
  }

  function handleBackInput() {
    if (screen !== 'game') {
      return
    }

    if (revealInlineDialogTextFromButtonPress()) {
      return
    }

    if (isBlockingMessageOverlay) {
      advanceMessageOverlay()
      return
    }

    if (isAmbientMessageOverlay) {
      dismissAmbientMessageOverlay()
      return
    }

    if (overlay?.type === 'inventory' || overlay?.type === 'journal') {
      closeOverlay()
      return
    }

    if (overlay?.type === 'shopBuy' || overlay?.type === 'shopSell') {
      resolveOverlay(null)
      return
    }

    if (overlay?.type === 'mapView' || overlay?.type === 'credits') {
      resolveOverlay(undefined)
      return
    }

    if (overlay) {
      return
    }

    if (isViewportMaximized) {
      setIsViewportMaximized(false)
      return
    }

    setScreen('menu')
  }

  function handleInventoryShortcut() {
    const allowBattlePauseInventory = Boolean(runtimeRef.current?.battle?.duel?.allowInventory)

    if (revealInlineDialogTextFromButtonPress()) {
      return
    }

    if (screen !== 'game' || overlay) {
      return
    }

    if (!allowBattlePauseInventory && (!canControl || gameInteractionLockRef.current)) {
      return
    }

    openInventory()
  }

  function triggerInventorySelection() {
    const allowBattlePauseInventory = Boolean(runtimeRef.current?.battle?.duel?.allowInventory)

    if (gameInteractionLockRef.current && !allowBattlePauseInventory) {
      return
    }

    if (allowBattlePauseInventory) {
      void applyInventorySelection()
      return
    }

    void runLockedGameInteraction(() => applyInventorySelection())
  }

  function handleBagShortcut() {
    if (screen !== 'game') {
      return
    }

    if (overlay?.type === 'inventory') {
      triggerInventorySelection()
      return
    }

    handleInventoryShortcut()
  }

  function handleJournalShortcut() {
    if (revealInlineDialogTextFromButtonPress()) {
      return
    }

    if (screen !== 'game' || overlay || !canControl || gameInteractionLockRef.current) {
      return
    }

    void showJournal()
  }

  function handleSaveShortcut() {
    if (revealInlineDialogTextFromButtonPress()) {
      return
    }

    if (screen !== 'game' || overlay || !canControl || gameInteractionLockRef.current) {
      return
    }

    void runLockedGameInteraction(() => quicksaveCurrentGame())
  }

  function handleLoadShortcut() {
    if (revealInlineDialogTextFromButtonPress()) {
      return
    }

    if (screen !== 'game' || overlay || !canControl || gameInteractionLockRef.current) {
      return
    }

    void runLockedGameInteraction(() => quickloadCurrentGame())
  }

  const handleGlobalKeyDown = useEffectEvent((event: KeyboardEvent) => {
    const isPlainContinueKey =
      !event.isComposing &&
      !(event.ctrlKey && event.key !== 'Control') &&
      !(event.altKey && event.key !== 'Alt') &&
      !(event.metaKey && event.key !== 'Meta')
    const isDirectionalKey =
      event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === 'ArrowLeft' || event.key === 'ArrowRight'

    if (screen === 'bootLogo' || screen === 'bootLogo2') {
      event.preventDefault()
      setScreen('menu')
      return
    }

    if (screen === 'menu') {
      if (event.key === 'Escape' && hasActiveRun) {
        event.preventDefault()
        resumeGame()
        return
      }

      if (event.key === 'ArrowUp') {
        event.preventDefault()
        setMenuSelection((previous) => (previous > 0 ? previous - 1 : menuEntries.length - 1))
        return
      }

      if (event.key === 'ArrowDown') {
        event.preventDefault()
        setMenuSelection((previous) => (previous < menuEntries.length - 1 ? previous + 1 : 0))
        return
      }

      if (event.key === 'Home') {
        event.preventDefault()
        setMenuSelection(0)
        return
      }

      if (event.key === 'End') {
        event.preventDefault()
        setMenuSelection(menuEntries.length - 1)
        return
      }

      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault()
        menuEntries[menuSelection]?.action()
        return
      }
    }

    if (screen === 'death' && isPlainContinueKey) {
      event.preventDefault()
      acknowledgeDeathScreen()
      return
    }

    if (screen === 'newGame') {
      const activeElement = document.activeElement
      const avatarIndex = newGameAvatarButtonRefs.current.findIndex((button) => button === activeElement)
      const isNameInputActive = activeElement === newGameNameInputRef.current
      const isStartButtonActive = activeElement === newGameStartButtonRef.current
      const isCloseButtonActive = activeElement === newGameCloseButtonRef.current

      if (isNameInputActive && event.key === 'Enter') {
        event.preventDefault()
        void startNewGame()
        return
      }

      if (isNameInputActive && event.key === 'ArrowDown') {
        event.preventDefault()
        focusSelectedNewGameAvatar()
        return
      }

      if (avatarIndex >= 0) {
        const column = avatarIndex % 3

        if (event.key === 'ArrowLeft') {
          event.preventDefault()
          focusNewGameAvatarByIndex(column === 0 ? avatarIndex + 2 : avatarIndex - 1)
          return
        }

        if (event.key === 'ArrowRight') {
          event.preventDefault()
          focusNewGameAvatarByIndex(column === 2 ? avatarIndex - 2 : avatarIndex + 1)
          return
        }

        if (event.key === 'ArrowUp') {
          event.preventDefault()

          if (avatarIndex >= 3) {
            focusNewGameAvatarByIndex(avatarIndex - 3)
          } else {
            newGameNameInputRef.current?.focus()
          }
          return
        }

        if (event.key === 'ArrowDown') {
          event.preventDefault()

          if (avatarIndex + 3 < ui.avatarOptions.length) {
            focusNewGameAvatarByIndex(avatarIndex + 3)
          } else {
            newGameStartButtonRef.current?.focus()
          }
          return
        }
      }

      if (isStartButtonActive && event.key === 'ArrowUp') {
        event.preventDefault()
        focusSelectedNewGameAvatar()
        return
      }

      if (isStartButtonActive && event.key === 'ArrowRight') {
        event.preventDefault()
        newGameCloseButtonRef.current?.focus()
        return
      }

      if (isCloseButtonActive && event.key === 'ArrowLeft') {
        event.preventDefault()
        newGameStartButtonRef.current?.focus()
        return
      }
    }

    if (screen === 'newGame' && event.key === 'Escape') {
      event.preventDefault()
      setScreen('menu')
      return
    }

    if (screen === 'creditsMenu' && (event.key === 'Enter' || event.key === 'Escape' || event.key === ' ')) {
      event.preventDefault()
      setScreen('menu')
      return
    }

    if (screen !== 'game') {
      return
    }

    const eventTarget = event.target
    const isEditableTarget =
      eventTarget instanceof HTMLInputElement ||
      eventTarget instanceof HTMLTextAreaElement ||
      eventTarget instanceof HTMLSelectElement ||
      (eventTarget instanceof HTMLElement && eventTarget.isContentEditable)

    if (isEditableTarget) {
      return
    }

    const isStandaloneModifierKey =
      event.key === 'Shift' || event.key === 'Control' || event.key === 'Alt' || event.key === 'Meta' || event.key === 'CapsLock'

    if (inlineDialogOverlay && !isInlineDialogTextFullyVisible && isPlainContinueKey && !isStandaloneModifierKey) {
      event.preventDefault()
      revealInlineDialogText()
      return
    }

    if (overlay?.type === 'message' && isPlainContinueKey && !isDirectionalKey) {
      event.preventDefault()

      if (isBlockingMessageOverlay) {
        advanceMessageOverlay()
        return
      }

      dismissAmbientMessageOverlay()
      return
    }

    if (overlay?.type === 'choice') {
      if (event.key >= '1' && event.key <= '9') {
        const optionIndex = Number.parseInt(event.key, 10) - 1

        if (optionIndex < overlay.options.length) {
          event.preventDefault()
          resolveOverlay(optionIndex + 1)
        }
        return
      }
    }

    if (event.key === 'ArrowUp') {
      event.preventDefault()
      handleDirectionalInput('up')
    } else if (event.key === 'ArrowDown') {
      event.preventDefault()
      handleDirectionalInput('down')
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault()
      handleDirectionalInput('left')
    } else if (event.key === 'ArrowRight') {
      event.preventDefault()
      handleDirectionalInput('right')
    } else if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      handleConfirmInput()
    } else if (event.key === 'Escape') {
      event.preventDefault()
      handleBackInput()
    } else if (event.key.toLowerCase() === 'b' && (overlay?.type === 'inventory' || !overlay)) {
      event.preventDefault()
      handleBagShortcut()
    } else if (event.key.toLowerCase() === 'i') {
      event.preventDefault()
      handleInventoryShortcut()
    } else if (event.key.toLowerCase() === 'j') {
      event.preventDefault()
      handleJournalShortcut()
    } else if (event.key.toLowerCase() === 's') {
      event.preventDefault()
      handleSaveShortcut()
    } else if (event.key.toLowerCase() === 'l') {
      event.preventDefault()
      handleLoadShortcut()
    } else if (event.key.toLowerCase() === 'f' && event.shiftKey && fullscreenSupported) {
      event.preventDefault()
      void toggleFullscreen()
    } else if (event.key.toLowerCase() === 'f') {
      event.preventDefault()
      toggleViewportMaximized()
    }
  })

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      handleGlobalKeyDown(event)
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => {
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [])

  function closeOverlay() {
    overlayResolverRef.current = null
    setDialogPageIndex(0)
    setDialogChoiceSelection(1)
    setShopSelection(0)
    setTextInputValue('')
    setOverlay(null)
  }

  function resolveOverlay(value: unknown) {
    const resolver = overlayResolverRef.current
    overlayResolverRef.current = null
    setOverlay(null)
    setDialogPageIndex(0)
    setDialogChoiceSelection(1)
    setShopSelection(0)
    setTextInputValue('')
    resolver?.(value)
  }

  function advanceMessageOverlay() {
    if (overlay?.type !== 'message' || overlay.blocking === false) {
      return false
    }

    if (!isInlineDialogTextFullyVisible) {
      revealInlineDialogText()
      return false
    }

    const pages = paginateDialogText(overlay.text, dialogLineLength)
    if (dialogPageIndex < pages.length - 1) {
      setDialogPageIndex((previous) => previous + 1)
      return false
    }

    return closeMessageOverlay()
  }

  function closeMessageOverlay() {
    if (overlayRef.current?.type !== 'message') {
      return false
    }

    const resolver = overlayResolverRef.current
    overlayResolverRef.current = null
    setOverlay(null)
    setDialogPageIndex(0)
    setDialogVisibleCharacterCount(0)
    resolver?.(undefined)
    return true
  }

  function revealInlineDialogText() {
    setDialogVisibleCharacterCount(inlineDialogText.length)
  }

  function revealInlineDialogTextFromButtonPress() {
    if (screen !== 'game') {
      return false
    }

    if (
      (overlay?.type === 'message' || overlay?.type === 'choice' || overlay?.type === 'textInput') &&
      !isInlineDialogTextFullyVisible
    ) {
      revealInlineDialogText()
      return true
    }

    return false
  }

  function handleMessageOverlayClick() {
    if (overlay?.type !== 'message') {
      return
    }

    if (!isInlineDialogTextFullyVisible) {
      revealInlineDialogText()
      return
    }

    if (overlay.blocking !== false) {
      advanceMessageOverlay()
      return
    }

    dismissAmbientMessageOverlay()
  }

  function dismissAmbientMessageOverlay() {
    setOverlay((current) => (current?.type === 'message' && current.blocking === false ? null : current))
    setDialogPageIndex(0)
    setDialogVisibleCharacterCount(0)
  }

  function scheduleMoveAfterMessageDismiss(direction: Direction) {
    window.requestAnimationFrame(() => {
      const activeRuntime = runtimeRef.current

      if (
        screenRef.current !== 'game' ||
        overlayRef.current !== null ||
        eventDepthRef.current !== 0 ||
        gameInteractionLockRef.current ||
        !activeRuntime?.gameStarted ||
        activeRuntime.gameEnded ||
        activeRuntime.battle?.duel
      ) {
        return
      }

      void runLockedGameInteraction(() => movePlayer(direction))
    })
  }

  function moveInventorySelection(direction: Direction) {
    setInventorySelection((previous) => {
      if (direction === 'up') {
        return previous > 10 ? previous - 10 : previous
      }

      if (direction === 'down') {
        return previous <= 10 ? previous + 10 : previous
      }

      if (direction === 'right') {
        return previous !== 10 && previous !== 20 ? previous + 1 : previous - 9
      }

      return previous !== 1 && previous !== 11 ? previous - 1 : previous + 9
    })
  }

  function moveShopSelection(step: number, itemCount: number) {
    if (itemCount <= 0) {
      return
    }

    setShopSelection((previous) => wrapIndex(previous + step, itemCount))
  }

  async function waitForMessage(text: string, title?: string) {
    if (text.trim() === '') {
      return
    }

    setDialogPageIndex(0)

    await new Promise<void>((resolve) => {
      overlayResolverRef.current = () => resolve()
      setOverlay({
        type: 'message',
        text,
        title,
        blocking: true,
      })
    })
  }

  async function waitForChoice(text: string, options: string[], width?: number) {
    return new Promise<number>((resolve) => {
      setDialogChoiceSelection(1)
      overlayResolverRef.current = (value) => resolve((value as number | undefined) ?? 1)
      setOverlay({
        type: 'choice',
        text,
        fallbackText: text.trim() === '' ? retainedInlineDialogTextRef.current : undefined,
        options,
        width,
      })
    })
  }

  async function waitForTextInput(text: string) {
    return new Promise<string>((resolve) => {
      overlayResolverRef.current = (value) => resolve(String(value ?? ''))
      setDialogPageIndex(0)
      setTextInputValue('')
      setOverlay({
        type: 'textInput',
        text,
        fallbackText: text.trim() === '' ? retainedInlineDialogTextRef.current : undefined,
      })
    })
  }

  async function waitForBuyShop(
    text: string,
    items: InventorySlot[],
    prices: number[],
    notice = '',
    initialSelection = 0,
  ) {
    return new Promise<number | null>((resolve) => {
      setShopSelection(wrapIndex(initialSelection, items.length))
      overlayResolverRef.current = (value) => resolve((value as number | null | undefined) ?? null)
      setOverlay({
        type: 'shopBuy',
        text,
        items,
        prices,
        notice,
      })
    })
  }

  async function waitForSellShop(text: string, allowedTypes: string[], multiplier: number, notice = '', initialSelection = 0) {
    return new Promise<number | null>((resolve) => {
      const activeRuntime = runtimeRef.current
      const sellEntries = getSellEntries(activeRuntime, { type: 'shopSell', text, allowedTypes, multiplier, notice })
      setShopSelection(wrapIndex(initialSelection, sellEntries.length))
      overlayResolverRef.current = (value) => resolve((value as number | null | undefined) ?? null)
      setOverlay({
        type: 'shopSell',
        text,
        allowedTypes,
        multiplier,
        notice,
      })
    })
  }

  async function waitForMapView() {
    await new Promise<void>((resolve) => {
      overlayResolverRef.current = () => resolve()
      setOverlay({ type: 'mapView' })
    })
  }

  async function waitForCredits() {
    await new Promise<void>((resolve) => {
      overlayResolverRef.current = () => resolve()
      setOverlay({
        type: 'credits',
        lines: [...ui.creditLines],
      })
    })
  }

  async function performFade(mode: 'out' | 'in', time: number) {
    const durationMs = Math.max(100, time * 16)

    if (mode === 'out') {
      setOverlay({ type: 'fade', mode: 'out', durationMs })
      await sleep(durationMs)
      setOverlay({ type: 'fade', mode: 'hold' })
      return
    }

    setOverlay({ type: 'fade', mode: 'in', durationMs })
    await sleep(durationMs)
    setOverlay(null)
  }

  async function toggleFullscreen() {
    if (!fullscreenSupported) {
      return
    }

    if (document.fullscreenElement) {
      await document.exitFullscreen()
      return
    }

    await document.documentElement.requestFullscreen()
  }

  function toggleViewportMaximized() {
    setIsViewportMaximized((previous) => !previous)
  }

  function openInventory() {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime) {
      return
    }

    setInventorySelection(getFirstFilledBagSlot(activeRuntime))
    setOverlay({ type: 'inventory' })
  }

  async function showJournal() {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime) {
      return
    }

    setOverlay({ type: 'journal' })
  }

  function openMainMenu(clearRun = false) {
    if (clearRun) {
      runtimeRef.current = null
      refresh()
    }

    setOverlay(null)
    setScreen('menu')
  }

  function resumeGame() {
    if (!hasActiveRun) {
      return
    }

    setSaveScreenMessage('')
    setScreen('game')
  }

  function acknowledgeDeathScreen() {
    runtimeRef.current = null
    setOverlay(null)
    setScreen('menu')
    refresh()
  }

  async function saveGameToSlot(slotId: SaveSlotId, showScreenMessage = true) {
    const activeRuntime = runtimeRef.current
    const slotDefinition = getSaveSlotDefinitions().find((slot) => slot.id === slotId)

    if (!activeRuntime) {
      return
    }

    try {
      await writeSaveRecord(createSaveRecord(slotId, activeRuntime))
      setSaveSlots([await readSavedGameSummary()])

      if (showScreenMessage) {
        const saveMessage = ui.saveStored(slotDefinition?.label ?? getSaveSlotDefinitions()[0].label)
        setSaveScreenMessage(saveMessage)
        setDialogPageIndex(0)
        setOverlay({
          type: 'message',
          text: saveMessage,
          blocking: false,
        })
      }

      activeRuntime.status = ui.saveStored(slotDefinition?.label ?? getSaveSlotDefinitions()[0].label)
      refresh()
    } catch (error) {
      const message = error instanceof Error ? error.message : ui.saveWriteFailure

      if (showScreenMessage) {
        setSaveScreenMessage(message)
      }

      activeRuntime.status = message
      refresh()
    }
  }

  async function quicksaveCurrentGame() {
    await saveGameToSlot('quicksave')
  }

  async function quickloadCurrentGame() {
    const message = await loadGameFromSlot('quicksave')

    if (!message) {
      return
    }

    setSaveScreenMessage(message)
    setDialogPageIndex(0)
    setOverlay({
      type: 'message',
      text: message,
      blocking: false,
    })
  }

  async function loadSavedGameFromMenu() {
    if (!savedGameSummary?.hasSave) {
      setSaveScreenMessage(ui.saveMissing)
      return
    }

    await loadGameFromSlot('quicksave')
  }

  async function loadGameFromSlot(slotId: SaveSlotId) {
    const content = contentRef.current

    if (!content) {
      return ui.saveLoadFailed
    }

    try {
      const record = await readSaveRecord(slotId)

      if (!record) {
        const message = ui.saveEmpty
        const activeRuntime = runtimeRef.current

        setSaveScreenMessage(message)

        if (activeRuntime) {
          activeRuntime.status = message
          refresh()
        }

        return message
      }

      const restoredRuntime = restoreRuntime(content, record.runtime)
      const loadMessage = ui.saveLoaded

      await performFade('out', Math.round(MAP_TRANSITION_FADE_MS / 16))

      restoredRuntime.status = loadMessage
      runtimeRef.current = restoredRuntime
      setDialogPageIndex(0)
      setDialogVisibleCharacterCount(0)
      setTextInputValue('')
      setScreen('game')
      setSaveScreenMessage('')
      refresh()
      await performFade('in', Math.round(MAP_TRANSITION_FADE_MS / 16))
      setDialogPageIndex(0)
      setOverlay({
        type: 'message',
        text: loadMessage,
        blocking: false,
      })
      return null
    } catch (error) {
      const message = error instanceof Error ? error.message : ui.saveLoadFailed
      const activeRuntime = runtimeRef.current

      setSaveScreenMessage(message)

      if (activeRuntime) {
        activeRuntime.status = message
        refresh()
      }

      return message
    }
  }

  async function jumpToDebugMap() {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime || !debugMapSelection) {
      return
    }

    activeRuntime.gameEnded = false
    setScreen('game')
    await transitionToMap(debugMapSelection, 0, 0, 0)
  }

  function awardExperience(runtimeToMutate: Runtime, formula: string) {
    const gained = diceNumber(formula)

    if (gained > 0) {
      runtimeToMutate.stats[3] += gained
      runtimeToMutate.status = ui.experienceGain(gained)
    }
  }

  async function applyPostMutation(runtimeToMutate: Runtime, context: EventContext, mutation: PostEventMutation) {
    awardExperience(runtimeToMutate, mutation.expFormula)
    handleLevelUps(runtimeToMutate)

    if (runtimeToMutate.stats[1] <= 0) {
      return
    }

    const activeMapToMutate = getActiveMap(runtimeToMutate)
    const targetCell = getMapCell(activeMapToMutate, context.targetX, context.targetY)

    if (!targetCell) {
      if (mutation.infoAfter < -1) {
        await executeEventInternal(-mutation.infoAfter, context)
      }
      return
    }

    if (mutation.infoAfter < -1) {
      await executeEventInternal(-mutation.infoAfter, context)
    } else if (mutation.infoAfter > -1) {
      targetCell.event = mutation.infoAfter
    }

    if (mutation.mapAfter !== 0) {
      targetCell.terrain = mutation.mapAfter
    }

    if (mutation.objectAfter !== -1) {
      targetCell.object = mutation.objectAfter
    }

    refresh()
  }

  function handleLevelUps(runtimeToMutate: Runtime) {
    while (runtimeToMutate.stats[3] >= 500 * runtimeToMutate.stats[4]) {
      runtimeToMutate.stats[5] += 2
      runtimeToMutate.stats[6] += 2
      runtimeToMutate.stats[10] += 1
      runtimeToMutate.stats[2] += 10
      runtimeToMutate.stats[1] = runtimeToMutate.stats[2]
      runtimeToMutate.stats[3] -= 500 * runtimeToMutate.stats[4]
      runtimeToMutate.stats[4] += 1
      runtimeToMutate.status = ui.levelUp(runtimeToMutate.stats[4])
    }
  }

  async function handleDeath() {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime || activeRuntime.gameEnded) {
      return
    }

    activeRuntime.gameEnded = true
    activeRuntime.battle = null
    activeRuntime.status = ui.deathStatus
    refresh()
    setScreen('death')
  }

  async function startNewGame() {
    const content = contentRef.current

    if (!content) {
      return
    }

    setSaveScreenMessage('')
    initialMapRevealPendingRef.current = true
    setHideSceneUntilReveal(true)
    runtimeRef.current = createNewRuntime(content, startName.trim() || ui.defaultPlayerName, startAvatar)
    setScreen('game')
    refresh()

    try {
      await runTopLevelEvent(1, {
        targetX: runtimeRef.current.player.x,
        targetY: runtimeRef.current.player.y,
        rawEventCode: 1,
        negativeTrigger: false,
      })
    } finally {
      if (initialMapRevealPendingRef.current) {
        initialMapRevealPendingRef.current = false
        setHideSceneUntilReveal(false)
      }
    }
  }

  async function runTopLevelEvent(eventCode: number, context: EventContext) {
    eventDepthRef.current += 1

    try {
      await executeEventInternal(eventCode, context)
    } finally {
      eventDepthRef.current = Math.max(0, eventDepthRef.current - 1)
      const activeRuntime = runtimeRef.current

      if (activeRuntime) {
        handleLevelUps(activeRuntime)
        refresh()
      }
    }
  }

  async function executeEventInternal(eventCode: number, context: EventContext): Promise<void> {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime || eventCode === 0) {
      return
    }

    let enemyCount = 0
    let normalizedCode = eventCode

    if (Math.abs(normalizedCode) > 10000) {
      enemyCount = Math.abs(normalizedCode) % 100
      normalizedCode = Math.sign(normalizedCode) * Math.trunc(Math.abs(normalizedCode) / 100)
    }

    const block = activeRuntime.eventsById[Math.abs(normalizedCode)]

    if (!block) {
      activeRuntime.status = ui.missingEvent(Math.abs(normalizedCode))
      refresh()
      return
    }

    const cursor = createCursor(block.lines)
    const eventType = block.type

      switch (eventType) {
      case 1: {
        await waitForMessage(cursor.readString())
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 2: {
        await waitForMessage(cursor.readString())
        const message = addInventoryItem(activeRuntime, cursor.readString(), cursor.readInt())
        if (message) {
          activeRuntime.status = message
        }
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 3: {
        await waitForMessage(cursor.readString())
        const itemName = cursor.readString()
        const amount = cursor.readInt()
        const slot = findItemSlot(activeRuntime, itemName)

        if (slot > 0) {
          removeInventoryAmount(activeRuntime, slot, amount)
        }

        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 4: {
        await waitForMessage(cursor.readString())
        const attribute = cursor.readInt()
        activeRuntime.stats[attribute] += diceNumber(cursor.readString())
        activeRuntime.stats[1] = Math.min(activeRuntime.stats[1], activeRuntime.stats[2])
        activeRuntime.stats[8] = Math.min(activeRuntime.stats[8], activeRuntime.stats[9])
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 5: {
        await waitForMessage(cursor.readString())
        const attribute = cursor.readInt()
        activeRuntime.stats[attribute] = Math.max(0, activeRuntime.stats[attribute] - diceNumber(cursor.readString()))
        activeRuntime.stats[1] = Math.min(activeRuntime.stats[1], activeRuntime.stats[2])
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 6: {
        await waitForMessage(activeRuntime.almanach || ui.noJournalEntry, ui.journalMessageTitle)
        return
      }

      case 7: {
        await waitForMessage(cursor.readString())
        activeRuntime.almanach = cursor.readString()
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 8: {
        const text = cursor.readString()
        const item = cursor.readString()
        const amount = cursor.readInt()
        const price = cursor.readInt()

        if (activeRuntime.stats[7] - price >= 0) {
          activeRuntime.stats[7] -= price
          const message = addInventoryItem(activeRuntime, item, amount)
          activeRuntime.status = message || text
          if (text.trim()) {
            await waitForMessage(text)
          }
        } else {
          await waitForMessage(ui.notEnoughMoney)
        }

        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 9: {
        await waitForMessage(cursor.readString())
        const optionCount = cursor.readInt()
        const thresholds = Array.from({ length: optionCount }, () => cursor.readInt())
        const redirects = Array.from({ length: optionCount }, () => cursor.readInt())
        const roll = randomInt(1, 10000)
        let selectedIndex = redirects.length - 1

        for (let index = 0; index < thresholds.length; index += 1) {
          if (thresholds[index] >= roll) {
            selectedIndex = index
            break
          }
        }

        await executeEventInternal(redirects[selectedIndex], context)
        return
      }

      case 10: {
        const text = cursor.readString()
        const width = cursor.readInt()
        const optionCount = cursor.readInt()
        const options = Array.from({ length: optionCount }, () => cursor.readString())
        const redirects = Array.from({ length: optionCount }, () => cursor.readInt())
        const answer = await waitForChoice(text, options, width)
        await executeEventInternal(redirects[Math.max(0, answer - 1)], context)
        return
      }

      case 11: {
        await waitForMessage(cursor.readString())
        const attribute = cursor.readInt()
        const amount = cursor.readInt()
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        await executeEventInternal(activeRuntime.stats[attribute] >= amount ? eventTrue : eventFalse, context)
        return
      }

      case 12: {
        await waitForMessage(cursor.readString())
        const itemName = cursor.readString()
        const amount = cursor.readInt()
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        await executeEventInternal(countItem(activeRuntime, itemName) >= amount ? eventTrue : eventFalse, context)
        return
      }

      case 13: {
        await waitForMessage(cursor.readString())
        const itemName = cursor.readString()
        const amount = cursor.readInt()
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        const slot = findItemSlot(activeRuntime, itemName)

        if (slot > 0 && (activeRuntime.inventory[slot]?.count ?? 0) >= amount) {
          removeInventoryAmount(activeRuntime, slot, amount)
          await executeEventInternal(eventTrue, context)
          return
        }

        await executeEventInternal(eventFalse, context)
        return
      }

      case 14: {
        const text = cursor.readString()
        const answerCount = cursor.readInt()
        const answers = Array.from({ length: answerCount }, () => cursor.readString())
        const redirects = Array.from({ length: answerCount }, () => cursor.readInt())
        const wrongEvent = cursor.readInt()
        const submitted = (await waitForTextInput(text)).trim().toUpperCase()
        const matchIndex = answers.findIndex((answer) => answer.toUpperCase() === submitted)
        await executeEventInternal(matchIndex >= 0 ? redirects[matchIndex] : wrongEvent, context)
        return
      }

      case 15: {
        const text = cursor.readString()
        const allowedTypes = Array.from({ length: 5 }, () => cursor.readString())
        const multiplier = cursor.readInt()

        for (;;) {
          const selectedSlot = await waitForSellShop(text, allowedTypes, multiplier)

          if (selectedSlot === null) {
            return
          }

          const selectedItem = activeRuntime.inventory[selectedSlot]

          if (!selectedItem) {
            continue
          }

          const saleValue =
            selectedItem.type === 'E'
              ? TOOL_VALUE * selectedItem.count * multiplier
              : selectedItem.power * selectedItem.count * multiplier

          activeRuntime.stats[7] += saleValue
          removeInventoryAmount(activeRuntime, selectedSlot, selectedItem.count)
          activeRuntime.status = ui.soldItem(selectedItem.name)
          refresh()
        }
      }

      case 16: {
        const text = cursor.readString()
        const itemCount = cursor.readInt()
        const items = Array.from({ length: itemCount }, () => parseItemString(cursor.readString())).filter(
          (item): item is InventorySlot => item !== null,
        )
        const prices = Array.from({ length: itemCount }, () => cursor.readInt())
        let shopNotice = ''
        let initialSelection = 0

        for (;;) {
          const selectedIndex = await waitForBuyShop(text, items, prices, shopNotice, initialSelection)
          shopNotice = ''

          if (selectedIndex === null) {
            return
          }

          const item = items[selectedIndex]
          const price = prices[selectedIndex] ?? 0

          if (!item) {
            continue
          }

          initialSelection = selectedIndex

          if (activeRuntime.stats[7] - price < 0) {
            shopNotice = ui.notEnoughGold
            continue
          }

          activeRuntime.stats[7] -= price
          const message = addInventoryItem(activeRuntime, item.raw, 1)
          activeRuntime.status = message || ui.boughtItem(item.name)
          refresh()
        }
      }

      case 20: {
        const text = cursor.readString()
        const enemyAttack = cursor.readInt()
        const enemyDefense = cursor.readInt()
        const enemyDexterity = cursor.readInt()
        const enemyGoldFormula = cursor.readString()
        const enemyExpFormula = cursor.readString()
        const enemySprite = cursor.readInt()
        const enemySpeed = cursor.readInt()
        const enemyName = cursor.readString()
        const enemyDescription = cursor.readString()
        const enemyHpFormula = cursor.readString()
        const enemyReward = cursor.readString()
        const battleMapName = normalizeMapName(cursor.readString())
        const terrainPersistent = cursor.readInt() === 1
        const afterEventId = cursor.readInt()
        const sourceMap = activeRuntime.maps[activeRuntime.mapName]
        const sourceTargetCell = getMapCell(sourceMap, context.targetX, context.targetY)
        const battleBaseMap = activeRuntime.baseMaps[battleMapName]

        await waitForMessage(text)

        if (!battleBaseMap) {
          activeRuntime.status = ui.missingBattleMap(battleMapName)
          refresh()
          return
        }

        const battleMap = cloneMap(battleBaseMap)
        const exitDirections = {
          up: isPassable(getMapCell(sourceMap, context.targetX, context.targetY - 1)),
          down: isPassable(getMapCell(sourceMap, context.targetX, context.targetY + 1)),
          left: isPassable(getMapCell(sourceMap, context.targetX - 1, context.targetY)),
          right: isPassable(getMapCell(sourceMap, context.targetX + 1, context.targetY)),
        }

        if (context.negativeTrigger || terrainPersistent) {
          activeRuntime.player.x = Math.trunc(battleMap.width / 2)
          activeRuntime.player.y = Math.trunc(battleMap.height / 2)
        } else {
          switch (activeRuntime.player.facing) {
            case 0:
              activeRuntime.player.x = Math.trunc(battleMap.width / 2)
              activeRuntime.player.y = battleMap.height - 1
              break
            case 1:
              activeRuntime.player.x = Math.trunc(battleMap.width / 2)
              activeRuntime.player.y = 2
              break
            case 2:
              activeRuntime.player.x = battleMap.width - 1
              activeRuntime.player.y = Math.trunc(battleMap.height / 2)
              break
            case 3:
              activeRuntime.player.x = 2
              activeRuntime.player.y = Math.trunc(battleMap.height / 2)
              break
            default:
              break
          }
        }

        const parsedEnemyCount = enemyCount > 0 ? enemyCount : 1
        const enemies: BattleEnemy[] = []

        for (let index = 0; index < parsedEnemyCount; index += 1) {
          for (;;) {
            const x = randomInt(2, Math.max(2, battleMap.width - 1))
            const y = randomInt(2, Math.max(2, battleMap.height - 1))
            const cell = getMapCell(battleMap, x, y)

            if (!cell || cell.terrain <= 0 || cell.object !== 0) {
              continue
            }

            if (activeRuntime.player.x === x && activeRuntime.player.y === y) {
              continue
            }

            const rolledHp = Math.max(1, diceNumber(enemyHpFormula))
            cell.object = -enemySprite
            enemies.push({
              id: index + 1,
              x,
              y,
              hp: rolledHp,
              maxHp: rolledHp,
            })
            break
          }
        }

        if (sourceTargetCell) {
          activeRuntime.status = ui.enemiesAppear(enemyName, battleBaseMap.originalName)
        }

        activeRuntime.battle = {
          sourceMapName: activeRuntime.mapName,
          sourceTarget: {
            x: context.targetX,
            y: context.targetY,
          },
          sourceEventCode: context.rawEventCode,
          negativeTrigger: context.negativeTrigger,
          terrainPersistent,
          afterEventId,
          exitDirections,
          enemyAttack,
          enemyDefense,
          enemyDexterity,
          enemyGoldFormula,
          enemyExpFormula,
          enemySprite,
          enemySpeed,
          enemyName,
          enemyDescription,
          enemyHpFormula,
          enemyReward,
          map: battleMap,
          enemies,
          stepCounter: 0,
          duel: null,
        }

        refresh()
        return
      }

      case 21: {
        await waitForMessage(cursor.readString())
        setMapCell(getActiveMap(activeRuntime), context.targetX, context.targetY, {
          terrain: cursor.readInt(),
          event: cursor.readInt(),
          object: cursor.readInt(),
        })
        refresh()
        return
      }

      case 22: {
        await waitForMessage(cursor.readString())
        const playerX = cursor.readInt()
        const playerY = cursor.readInt()
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        await executeEventInternal(
          activeRuntime.player.x === playerX && activeRuntime.player.y === playerY ? eventTrue : eventFalse,
          context,
        )
        return
      }

      case 23: {
        await waitForMessage(cursor.readString())
        activeRuntime.player.x = cursor.readInt()
        activeRuntime.player.y = cursor.readInt()
        activeRuntime.status = ui.positionChanged(activeRuntime.player.x, activeRuntime.player.y)
        refresh()
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 24: {
        await waitForMessage(cursor.readString())
        const expectedTerrain = cursor.readInt()
        const expectedObject = cursor.readInt()
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        const cell = getMapCell(getActiveMap(activeRuntime), activeRuntime.player.x, activeRuntime.player.y)
        await executeEventInternal(
          cell?.terrain === expectedTerrain && cell?.object === expectedObject ? eventTrue : eventFalse,
          context,
        )
        return
      }

      case 25: {
        await waitForMessage(cursor.readString())
        const x = cursor.readInt()
        const y = cursor.readInt()
        setMapCell(getActiveMap(activeRuntime), x, y, {
          terrain: cursor.readInt(),
          event: cursor.readInt(),
          object: cursor.readInt(),
        })
        refresh()
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 26: {
        await waitForMessage(cursor.readString())
        const x = cursor.readInt()
        const y = cursor.readInt()
        const expectedTerrain = cursor.readInt()
        const expectedObject = cursor.readInt()
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        const cell = getMapCell(getActiveMap(activeRuntime), x, y)
        await executeEventInternal(
          cell?.terrain === expectedTerrain && cell?.object === expectedObject ? eventTrue : eventFalse,
          context,
        )
        return
      }

      case 27: {
        await waitForMessage(cursor.readString())
        const expectedMap = normalizeMapName(cursor.readString())
        const eventTrue = cursor.readInt()
        const eventFalse = cursor.readInt()
        await executeEventInternal(getActiveMapName(activeRuntime) === expectedMap ? eventTrue : eventFalse, context)
        return
      }

      case 28: {
        await waitForMessage(cursor.readString())
        const time = cursor.readInt()
        const nextEvent = cursor.readInt()
        await sleep(Math.max(100, time * 16))
        await executeEventInternal(nextEvent, context)
        return
      }

      case 30: {
        await waitForMessage(cursor.readString())
        const animatedObject = cursor.readInt()
        const time = cursor.readInt()
        let offsetX = cursor.readInt()
        let offsetY = cursor.readInt()
        const stepCount = cursor.readInt()
        const directions = cursor.readString()
        const map = getActiveMap(activeRuntime)
        let oldObject = 0

        setMapCell(map, activeRuntime.player.x + offsetX, activeRuntime.player.y + offsetY, {
          object: animatedObject,
        })
        refresh()
        await sleep(Math.max(100, time * 16))

        const post = createPostEventMutation(cursor)

        for (let index = 0; index < stepCount; index += 1) {
          setMapCell(map, activeRuntime.player.x + offsetX, activeRuntime.player.y + offsetY, {
            object: oldObject,
          })

          switch (directions[index]) {
            case 'X':
              offsetX += 1
              break
            case 'x':
              offsetX -= 1
              break
            case 'Y':
              offsetY += 1
              break
            case 'y':
              offsetY -= 1
              break
            default:
              break
          }

          oldObject = getMapCell(map, activeRuntime.player.x + offsetX, activeRuntime.player.y + offsetY)?.object ?? 0
          setMapCell(map, activeRuntime.player.x + offsetX, activeRuntime.player.y + offsetY, {
            object: animatedObject,
          })
          refresh()
          await sleep(Math.max(100, time * 16))
        }

        setMapCell(map, activeRuntime.player.x + offsetX, activeRuntime.player.y + offsetY, {
          object: oldObject,
        })
        refresh()
        await applyPostMutation(activeRuntime, context, post)
        return
      }

      case 40: {
        await waitForMessage(cursor.readString())
        const nextMapName = normalizeMapName(cursor.readString())
        const targetX = cursor.readInt()
        const targetY = cursor.readInt()
        const afterEventId = cursor.readInt()
        await transitionToMap(nextMapName, targetX, targetY, afterEventId)
        return
      }

      case 45: {
        await waitForMessage(cursor.readString())
        const time = cursor.readInt()
        const nextEvent = cursor.readInt()
        await performFade('out', time)
        await executeEventInternal(nextEvent, context)
        return
      }

      case 46: {
        await waitForMessage(cursor.readString())
        const time = cursor.readInt()
        const nextEvent = cursor.readInt()
        await performFade('in', time)
        await executeEventInternal(nextEvent, context)
        return
      }

      case 50: {
        await waitForMapView()
        return
      }

      case 51: {
        await waitForMessage(cursor.readString())
        activeRuntime.player.avatar = cursor.readInt()
        refresh()
        await applyPostMutation(activeRuntime, context, createPostEventMutation(cursor))
        return
      }

      case 99: {
        activeRuntime.gameEnded = true
        activeRuntime.status = ui.gameEndReached
        refresh()
        await waitForCredits()
        return
      }

      default: {
        activeRuntime.status = ui.unimplementedEventType(eventType)
        refresh()
      }
    }
  }

  async function transitionToMap(mapName: string, targetX: number, targetY: number, afterEventId: number) {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime) {
      return
    }

    const nextMap = activeRuntime.maps[mapName]

    if (!nextMap) {
      activeRuntime.status = ui.missingMap(mapName)
      refresh()
      return
    }

    if (!activeRuntime.battle) {
      const currentMap = activeRuntime.maps[activeRuntime.mapName]

      if (currentMap) {
        currentMap.start.x = activeRuntime.player.x
        currentMap.start.y = activeRuntime.player.y
      }
    }

    const isInitialReveal = initialMapRevealPendingRef.current

    if (!isInitialReveal) {
      setOverlay({ type: 'fade', mode: 'out', durationMs: MAP_TRANSITION_FADE_MS })
      await sleep(MAP_TRANSITION_FADE_MS)
      setOverlay({ type: 'fade', mode: 'hold' })
    }

    activeRuntime.battle = null
    activeRuntime.mapName = mapName
    activeRuntime.player.x = targetX > 0 ? targetX : nextMap.start.x
    activeRuntime.player.y = targetY > 0 ? targetY : nextMap.start.y
    activeRuntime.status = ui.mapChanged(nextMap.originalName)
    refresh()

    await sleep(80)

    if (isInitialReveal) {
      initialMapRevealPendingRef.current = false
      setHideSceneUntilReveal(false)
    }

    setOverlay({ type: 'fade', mode: 'in', durationMs: MAP_TRANSITION_FADE_MS })
    await sleep(MAP_TRANSITION_FADE_MS)
    setOverlay(null)

    if (afterEventId > 0) {
      await executeEventInternal(afterEventId, {
        targetX: activeRuntime.player.x,
        targetY: activeRuntime.player.y,
        rawEventCode: afterEventId,
        negativeTrigger: false,
      })
    }
  }

  async function returnFromBattle(mode: 'up' | 'down' | 'left' | 'right' | 'victory') {
    const activeRuntime = runtimeRef.current
    const battle = activeRuntime?.battle

    if (!activeRuntime || !battle) {
      return
    }

    const sourceMap = activeRuntime.maps[battle.sourceMapName]
    const sourceCell = getMapCell(sourceMap, battle.sourceTarget.x, battle.sourceTarget.y)

    if (sourceCell && !battle.terrainPersistent) {
      if (mode === 'victory' || battle.enemies.length === 0) {
        sourceCell.event = 0
        sourceCell.object = 0
      } else {
        const baseEvent = Math.trunc(Math.abs(battle.sourceEventCode) / 100)
        const remaining = baseEvent * 100 + battle.enemies.length
        sourceCell.event = battle.negativeTrigger ? -remaining : remaining
      }
    }

    activeRuntime.battle = null
    activeRuntime.mapName = battle.sourceMapName

    if (mode === 'victory') {
      activeRuntime.player.x = battle.sourceTarget.x
      activeRuntime.player.y = battle.sourceTarget.y
    } else if (mode === 'up') {
      activeRuntime.player.x = battle.sourceTarget.x
      activeRuntime.player.y = battle.sourceTarget.y - 1
    } else if (mode === 'down') {
      activeRuntime.player.x = battle.sourceTarget.x
      activeRuntime.player.y = battle.sourceTarget.y + 1
    } else if (mode === 'left') {
      activeRuntime.player.x = battle.sourceTarget.x - 1
      activeRuntime.player.y = battle.sourceTarget.y
    } else if (mode === 'right') {
      activeRuntime.player.x = battle.sourceTarget.x + 1
      activeRuntime.player.y = battle.sourceTarget.y
    }

    activeRuntime.status = mode === 'victory' ? ui.battleWon : ui.battleEscaped
    refresh()

    if (battle.afterEventId > 0) {
      await executeEventInternal(battle.afterEventId, {
        targetX: activeRuntime.player.x,
        targetY: activeRuntime.player.y,
        rawEventCode: battle.afterEventId,
        negativeTrigger: false,
      })
    }
  }

  async function pauseBattleDuel(enemyId: number) {
    const activeBattle = runtimeRef.current?.battle
    const activeDuel = activeBattle?.duel

    if (!activeBattle || !activeDuel || activeDuel.enemyId !== enemyId) {
      return
    }

    activeDuel.allowInventory = true
    refresh()

    const pauseDeadline = Date.now() + BATTLE_PAUSE_MS
    let inventoryOpened = false

    for (;;) {
      const currentBattle = runtimeRef.current?.battle
      const currentDuel = currentBattle?.duel

      if (!currentBattle || !currentDuel || currentDuel.enemyId !== enemyId) {
        return
      }

      const currentOverlay = overlayRef.current

      if (currentOverlay?.type === 'inventory') {
        inventoryOpened = true
      }

      if (battleAdvanceStepCountRef.current > 0) {
        battleAdvanceStepCountRef.current -= 1
        break
      }

      if (inventoryOpened) {
        if (currentOverlay === null && eventDepthRef.current === 0) {
          break
        }
      } else if (Date.now() >= pauseDeadline) {
        break
      }

      await sleep(BATTLE_PAUSE_POLL_MS)
    }

    const resumedBattle = runtimeRef.current?.battle
    const resumedDuel = resumedBattle?.duel

    if (!resumedBattle || !resumedDuel || resumedDuel.enemyId !== enemyId) {
      return
    }

    resumedDuel.allowInventory = false
    refresh()
  }

  async function duelEnemy(enemyIndex: number) {
    const activeRuntime = runtimeRef.current
    const battle = activeRuntime?.battle

    if (!activeRuntime || !battle) {
      return
    }

    const enemy = battle.enemies[enemyIndex]

    if (!enemy) {
      return
    }

    battleAdvanceStepCountRef.current = 0
    battle.duel = {
      enemyId: enemy.id,
      enemyMaxHp: enemy.maxHp,
      playerHitText: '',
      previousPlayerHitText: '',
      enemyHitText: '',
      previousEnemyHitText: '',
      actionText: ui.battleOpeningLine(battle.enemyName),
      previousActionText: '',
      allowInventory: false,
    }
    refresh()
    await pauseBattleDuel(enemy.id)

    if (!runtimeRef.current?.battle || runtimeRef.current.battle.duel?.enemyId !== enemy.id) {
      return
    }

    while (enemy.hp > 0 && activeRuntime.stats[1] > 0) {
      const currentDuel = battle.duel

      if (!currentDuel || currentDuel.enemyId !== enemy.id) {
        return
      }

      const playerDexterity = activeRuntime.stats[10]
      const proHit = 100 / Math.max(1, playerDexterity + battle.enemyDexterity)
      const enemyHitChance = proHit * battle.enemyDexterity
      const playerHitChance = proHit * playerDexterity
      const playerGoesFirst = randomInt(1, 100) < playerHitChance

      if (playerGoesFirst) {
        if (randomInt(1, 100) < playerHitChance) {
          const damage = calculateBattleDamage(activeRuntime.stats[5], battle.enemyDefense)
          enemy.hp -= damage
          currentDuel.previousPlayerHitText = currentDuel.playerHitText
          currentDuel.playerHitText = `-${damage}`
          setBattleDuelAction(currentDuel, ui.battlePlayerHitLine(activeRuntime.player.name, battle.enemyName, damage))
        } else {
          currentDuel.previousPlayerHitText = currentDuel.playerHitText
          currentDuel.playerHitText = '-0'
          setBattleDuelAction(currentDuel, ui.battlePlayerMissLine(activeRuntime.player.name, battle.enemyName))
        }

        refresh()
        await pauseBattleDuel(enemy.id)

        if (!runtimeRef.current?.battle || runtimeRef.current.battle.duel?.enemyId !== enemy.id) {
          return
        }

        if (enemy.hp <= 0) {
          break
        }

        if (randomInt(1, 100) < enemyHitChance) {
          const damage = calculateBattleDamage(battle.enemyAttack, activeRuntime.stats[6])
          activeRuntime.stats[1] -= damage
          currentDuel.previousEnemyHitText = currentDuel.enemyHitText
          currentDuel.enemyHitText = `-${damage}`
          setBattleDuelAction(currentDuel, ui.battleEnemyHitLine(battle.enemyName, activeRuntime.player.name, damage))
        } else {
          currentDuel.previousEnemyHitText = currentDuel.enemyHitText
          currentDuel.enemyHitText = '-0'
          setBattleDuelAction(currentDuel, ui.battleEnemyMissLine(battle.enemyName, activeRuntime.player.name))
        }

        refresh()
        await pauseBattleDuel(enemy.id)

        if (!runtimeRef.current?.battle || runtimeRef.current.battle.duel?.enemyId !== enemy.id) {
          return
        }
      } else {
        if (randomInt(1, 100) < enemyHitChance) {
          const damage = calculateBattleDamage(battle.enemyAttack, activeRuntime.stats[6])
          activeRuntime.stats[1] -= damage
          currentDuel.previousEnemyHitText = currentDuel.enemyHitText
          currentDuel.enemyHitText = `-${damage}`
          setBattleDuelAction(currentDuel, ui.battleEnemyHitLine(battle.enemyName, activeRuntime.player.name, damage))
        } else {
          currentDuel.previousEnemyHitText = currentDuel.enemyHitText
          currentDuel.enemyHitText = '-0'
          setBattleDuelAction(currentDuel, ui.battleEnemyMissLine(battle.enemyName, activeRuntime.player.name))
        }

        refresh()
        await pauseBattleDuel(enemy.id)

        if (!runtimeRef.current?.battle || runtimeRef.current.battle.duel?.enemyId !== enemy.id) {
          return
        }

        if (activeRuntime.stats[1] <= 0) {
          break
        }

        if (randomInt(1, 100) < playerHitChance) {
          const damage = calculateBattleDamage(activeRuntime.stats[5], battle.enemyDefense)
          enemy.hp -= damage
          currentDuel.previousPlayerHitText = currentDuel.playerHitText
          currentDuel.playerHitText = `-${damage}`
          setBattleDuelAction(currentDuel, ui.battlePlayerHitLine(activeRuntime.player.name, battle.enemyName, damage))
        } else {
          currentDuel.previousPlayerHitText = currentDuel.playerHitText
          currentDuel.playerHitText = '-0'
          setBattleDuelAction(currentDuel, ui.battlePlayerMissLine(activeRuntime.player.name, battle.enemyName))
        }

        refresh()
        await pauseBattleDuel(enemy.id)

        if (!runtimeRef.current?.battle || runtimeRef.current.battle.duel?.enemyId !== enemy.id) {
          return
        }
      }
    }

    battle.duel = null
    battleAdvanceStepCountRef.current = 0
    refresh()

    if (activeRuntime.stats[1] <= 0) {
      activeRuntime.status = ui.battleTooStrong(battle.enemyName)
      refresh()
      await handleDeath()
      return
    }

    if (enemy.hp <= 0) {
      setMapCell(battle.map, enemy.x, enemy.y, { object: 0 })
      battle.enemies.splice(enemyIndex, 1)
      activeRuntime.stats[3] += diceNumber(battle.enemyExpFormula)
      activeRuntime.stats[7] += diceNumber(battle.enemyGoldFormula)
      const inventoryMessage = addInventoryItem(activeRuntime, battle.enemyReward, 1)
      handleLevelUps(activeRuntime)
      activeRuntime.status = inventoryMessage || ui.battleDefeated(battle.enemyName)
      refresh()

      if (inventoryMessage) {
        await waitForMessage(inventoryMessage, ui.battleTitle)
      }

      if (battle.enemies.length === 0) {
        await executeEventInternal(1000, {
          targetX: activeRuntime.player.x,
          targetY: activeRuntime.player.y,
          rawEventCode: 1000,
          negativeTrigger: false,
        })

        if (runtimeRef.current?.battle) {
          await returnFromBattle('victory')
        }
      }
    }
  }

  async function enemyTurn() {
    const activeRuntime = runtimeRef.current
    const battle = activeRuntime?.battle

    if (!activeRuntime || !battle || activeRuntime.stats[1] <= 0) {
      return
    }

    if (battle.enemies.length === 0) {
      await returnFromBattle('victory')
      return
    }

    let restartLoop = true

    while (restartLoop) {
      restartLoop = false

      for (let index = 0; index < battle.enemies.length; index += 1) {
        const enemy = battle.enemies[index]
        const nextPosition = chooseEnemyStep(enemy, activeRuntime.player, battle.map)

        if (nextPosition.x === enemy.x && nextPosition.y === enemy.y) {
          continue
        }

        setMapCell(battle.map, enemy.x, enemy.y, { object: 0 })
        enemy.x = nextPosition.x
        enemy.y = nextPosition.y
        setMapCell(battle.map, enemy.x, enemy.y, { object: -battle.enemySprite })
        refresh()

        if (enemy.x === activeRuntime.player.x && enemy.y === activeRuntime.player.y) {
          await duelEnemy(index)

          if (!runtimeRef.current?.battle || runtimeRef.current.stats[1] <= 0) {
            return
          }

          restartLoop = true
          break
        }
      }
    }

    if (runtimeRef.current?.battle) {
      runtimeRef.current.battle.stepCounter = 0
      refresh()
    }
  }

  async function movePlayer(direction: Direction) {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime) {
      return
    }

    activeRuntime.player.facing = DIRECTION_CONFIG[direction].facing
    activeRuntime.player.stepFrame = (activeRuntime.player.stepFrame + 1) % 4

    if (activeRuntime.battle) {
      const battle = activeRuntime.battle
      const targetX = activeRuntime.player.x + DIRECTION_CONFIG[direction].dx
      const targetY = activeRuntime.player.y + DIRECTION_CONFIG[direction].dy
      const targetCell = getMapCell(battle.map, targetX, targetY)
      battle.stepCounter += TILE_SIZE

      if (!isPassable(targetCell)) {
        activeRuntime.status = ui.wayBlocked(ui.directionLabels[direction])
        refresh()

        if (battle.stepCounter >= battle.enemySpeed * 10) {
          await enemyTurn()
        }

        return
      }

      dismissAmbientMessageOverlay()
      activeRuntime.player.x = targetX
      activeRuntime.player.y = targetY
      refresh()

      if (direction === 'left' && activeRuntime.player.x === 1 && battle.exitDirections.left) {
        await returnFromBattle('left')
        return
      }

      if (direction === 'right' && activeRuntime.player.x === battle.map.width && battle.exitDirections.right) {
        await returnFromBattle('right')
        return
      }

      if (direction === 'up' && activeRuntime.player.y === 1 && battle.exitDirections.up) {
        await returnFromBattle('up')
        return
      }

      if (direction === 'down' && activeRuntime.player.y === battle.map.height && battle.exitDirections.down) {
        await returnFromBattle('down')
        return
      }

      const enemyIndex = battle.enemies.findIndex(
        (enemy) => enemy.x === activeRuntime.player.x && enemy.y === activeRuntime.player.y,
      )

      if (enemyIndex >= 0) {
        await duelEnemy(enemyIndex)

        if (runtimeRef.current?.battle) {
          await enemyTurn()
        }

        return
      }

      if (battle.stepCounter >= battle.enemySpeed * 10) {
        await enemyTurn()
      }

      return
    }

    const currentMap = activeRuntime.maps[activeRuntime.mapName]
    const targetX = activeRuntime.player.x + DIRECTION_CONFIG[direction].dx
    const targetY = activeRuntime.player.y + DIRECTION_CONFIG[direction].dy
    const targetCell = getMapCell(currentMap, targetX, targetY)

    if (!isPassable(targetCell)) {
      activeRuntime.status = ui.wayBlocked(ui.directionLabels[direction])
      refresh()
      return
    }

    dismissAmbientMessageOverlay()
    activeRuntime.player.x = targetX
    activeRuntime.player.y = targetY
    refresh()

    if ((targetCell?.event ?? 0) < 0) {
      await runTopLevelEvent(-(targetCell?.event ?? 0), {
        targetX,
        targetY,
        rawEventCode: targetCell?.event ?? 0,
        negativeTrigger: (targetCell?.event ?? 0) <= -10000,
      })
    }
  }

  async function triggerAction() {
    const activeRuntime = runtimeRef.current

    if (!activeRuntime || activeRuntime.battle) {
      return
    }

    if (overlay?.type === 'message' && overlay.blocking === false) {
      dismissAmbientMessageOverlay()
      return
    }

    const facing = Object.values(DIRECTION_CONFIG).find((entry) => entry.facing === activeRuntime.player.facing)

    if (!facing) {
      return
    }

    const targetX = activeRuntime.player.x + facing.dx
    const targetY = activeRuntime.player.y + facing.dy
    const targetCell = getMapCell(activeRuntime.maps[activeRuntime.mapName], targetX, targetY)

    if (!targetCell || targetCell.event <= 0) {
      activeRuntime.status = ui.nothingToDo
      refresh()
      return
    }

    await runTopLevelEvent(targetCell.event, {
      targetX,
      targetY,
      rawEventCode: targetCell.event,
      negativeTrigger: false,
    })
  }

  async function applyInventorySelection() {
    const activeRuntime = runtimeRef.current
    const selected = activeRuntime?.inventory[inventorySelection]

    if (!activeRuntime || !selected) {
      return
    }

    if (selected.type === 'W' || selected.type === 'A' || selected.type === 'S' || selected.type === 'H' || selected.type === 'B') {
      activeRuntime.status = equipInventoryItem(activeRuntime, inventorySelection)
      refresh()
      return
    }

    if (selected.type === 'C') {
      activeRuntime.stats[1] = Math.min(activeRuntime.stats[2], activeRuntime.stats[1] + selected.power)
      removeInventoryAmount(activeRuntime, inventorySelection, 1)
      activeRuntime.status = ui.itemUsed(selected.name)
      setInventorySelection(getFirstFilledBagSlot(activeRuntime))
      refresh()
      return
    }

    if (selected.type === 'E' || selected.type === 'U') {
      closeOverlay()
      await runTopLevelEvent(selected.power, {
        targetX: activeRuntime.player.x,
        targetY: activeRuntime.player.y,
        rawEventCode: selected.power,
        negativeTrigger: false,
      })
      return
    }

    activeRuntime.status = ui.cannotUseDirectly
    refresh()
  }

  const selectedInventoryItem = runtime?.inventory[inventorySelection] ?? null
  const selectedInventoryDescription = selectedInventoryItem?.description?.trim() || ui.noDescription
  const shopEntries =
    inlineScreenOverlay?.type === 'shopBuy'
      ? inlineScreenOverlay.items.map((item, index) => ({
          key: `buy-${index}-${item.raw}`,
          item,
          price: inlineScreenOverlay.prices[index] ?? 0,
          actionValue: index,
          label: formatShopItemName(item),
        }))
      : inlineScreenOverlay?.type === 'shopSell'
        ? getSellEntries(runtime, inlineScreenOverlay).map(({ slot, item, price }) => ({
            key: `sell-${slot}-${item.raw}`,
            item,
            price,
            actionValue: slot,
            label: item.count > 1 ? `${item.count} ${formatShopItemName(item)}` : formatShopItemName(item),
          }))
        : []
  const selectedShopIndex = wrapIndex(shopSelection, shopEntries.length)
  const selectedShopEntry = shopEntries[selectedShopIndex] ?? null
  const shopCarouselIndices = getShopCarouselIndices(shopEntries.length, selectedShopIndex)
  const shopPromptText =
    inlineScreenOverlay?.type === 'shopBuy' || inlineScreenOverlay?.type === 'shopSell' ? inlineScreenOverlay.text : ''
  const shopNoticeText =
    inlineScreenOverlay?.type === 'shopBuy' || inlineScreenOverlay?.type === 'shopSell'
      ? (inlineScreenOverlay.notice ?? '')
      : ''
  const selectedShopDescription = selectedShopEntry?.item.description?.trim() || ui.noDescription
  const debugMapOptions = contentRef.current
    ? [...contentRef.current.manifest.maps].sort((left, right) => left.originalName.localeCompare(right.originalName))
    : []
  const screenArt = {
    logo: getAssetUrl('game-assets/logo.bmp'),
    logo2: getAssetUrl('game-assets/logo2.bmp'),
    death: getAssetUrl('game-assets/todessch.bmp'),
    title: getAssetUrl('game-assets/hinger3.bmp'),
  }
  const weaponBonus = runtime?.inventory[22]?.power ?? 0
  const armorBonus = (runtime?.inventory[23]?.power ?? 0) + (runtime?.inventory[24]?.power ?? 0)
  const dexterityBonus = (runtime?.inventory[21]?.power ?? 0) + (runtime?.inventory[25]?.power ?? 0)
  const journalText = runtime?.almanach || ui.noJournalEntry
  const landscapeNotice = requiresLandscapeMode ? (
    <section className="mobile-landscape-notice" aria-live="polite">
      <div className="mobile-landscape-card">
        <p className="eyebrow">{ui.mobilePlayEyebrow}</p>
        <h2>{ui.rotateLandscapeTitle}</h2>
        <p>{ui.rotateLandscapeBody}</p>
      </div>
    </section>
  ) : null

  if (screen !== 'game') {
    return (
      <main className="front-shell">
        {screen === 'loading' ? (
          <section className="front-window-shell">
            <section className="front-main-window front-loading-screen">
              <div className="front-window-body front-loading-body">
                <p className="eyebrow">{ui.loadingEyebrow}</p>
                <p className="intro">{loadingMessage}</p>
              </div>
            </section>
          </section>
        ) : null}

        {screen === 'bootLogo' || screen === 'bootLogo2' ? (
          <section className="front-window-shell">
            <button type="button" className="boot-screen boot-button" onClick={() => setScreen('menu')}>
              <section className="front-main-window front-boot-screen">
                <div className="front-window-banner front-boot-banner">
                  <img
                    src={screen === 'bootLogo' ? screenArt.logo : screenArt.logo2}
                    alt={screen === 'bootLogo' ? ui.bootLogoAltA : ui.bootLogoAltB}
                    className="front-window-art boot-art"
                  />
                </div>
                <span className="screen-skip">{ui.bootSkip}</span>
              </section>
            </button>
          </section>
        ) : null}

        {screen === 'menu' ? (
          <section className="front-window-shell">
            <section className="front-main-window front-menu-screen">
              <div className="front-window-banner front-menu-banner">
                <img src={screenArt.title} alt={ui.titleArtAlt} className="front-window-art front-menu-art" />
                <div className="front-menu-overlay">
                  <p className="eyebrow">{ui.menuTitle}</p>
                  <p className="front-subnote">{saveScreenMessage || ui.menuPrompt}</p>
                  <div className="menu-actions menu-overlay-actions">
                    {menuEntries.map((entry, index) => (
                      <button
                        key={entry.label}
                        type="button"
                        className={`${entry.variant === 'primary' ? 'primary-button' : 'ghost-button'} menu-button${menuSelection === index ? ' active' : ''}`}
                        onClick={entry.action}
                        onMouseEnter={() => setMenuSelection(index)}
                        onFocus={() => setMenuSelection(index)}
                      >
                        {entry.label}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </section>
          </section>
        ) : null}

        {screen !== 'loading' && screen !== 'bootLogo' && screen !== 'bootLogo2' && screen !== 'menu' ? (
          <section className="front-window-shell">
            {screen === 'death' ? (
              <button type="button" className="death-screen-button" onClick={() => acknowledgeDeathScreen()}>
                <section className="front-main-window death-window">
                  <div className="front-window-banner death-banner">
                    <img src={screenArt.death} alt={ui.deathAlt} className="front-window-art death-art" />
                  </div>
                  <span className="screen-skip death-hint">{ui.deathHint}</span>
                </section>
              </button>
            ) : (
              <section className={`front-main-window front-content-screen front-screen-${screen}`}>
                <div className="front-window-body front-fullscreen-body">
                  {screen === 'newGame' ? (
                    <>
                      <div className="front-screen-heading">
                        <p className="eyebrow">{ui.newGameTitle}</p>
                        <button
                          ref={newGameCloseButtonRef}
                          type="button"
                          className="window-close-button"
                          onClick={() => setScreen('menu')}
                          aria-label={ui.backToMenuAria}
                        >
                          X
                        </button>
                      </div>
                      <div className="front-screen-content front-newgame-layout">
                        <label className="field-label" htmlFor="player-name">
                          {ui.nameLabel}
                        </label>
                        <input
                          id="player-name"
                          ref={newGameNameInputRef}
                          className="text-field"
                          value={startName}
                          onChange={(event) => setStartName(event.target.value)}
                          maxLength={18}
                        />
                        <div className="front-avatar-section">
                          <p className="field-label">{ui.chooseAppearance}</p>
                          <div className="avatar-picker">
                            {ui.avatarOptions.map((avatar) => (
                              <button
                                key={avatar.id}
                                ref={(element) => {
                                  newGameAvatarButtonRefs.current[avatar.id - 1] = element
                                }}
                                type="button"
                                className={`avatar-button${startAvatar === avatar.id ? ' active' : ''}`}
                                onClick={() => setStartAvatar(avatar.id)}
                                onFocus={() => setStartAvatar(avatar.id)}
                              >
                                <span className="avatar-button-content">
                                  <AvatarPreview
                                    avatarId={avatar.id}
                                    spriteSheets={spriteSheets}
                                    frame={frontAnimationTick}
                                    className="avatar-preview-canvas"
                                  />
                                  <span className="avatar-label">{avatar.name}</span>
                                </span>
                              </button>
                            ))}
                          </div>
                        </div>
                      </div>
                      <div className="button-row front-screen-footer">
                        <button
                          ref={newGameStartButtonRef}
                          type="button"
                          className="primary-button"
                          onClick={() => void startNewGame()}
                          disabled={!contentRef.current}
                        >
                          {ui.startAdventure}
                        </button>
                      </div>
                    </>
                  ) : null}

                  {screen === 'creditsMenu' ? (
                    <>
                      <div className="front-screen-heading">
                        <p className="eyebrow">{ui.creditsTitle}</p>
                        <button type="button" className="window-close-button" onClick={() => setScreen('menu')} aria-label={ui.backToMenuAria}>
                          X
                        </button>
                      </div>
                      <div className="front-screen-content front-credits-layout">
                        <div className="credits-marquee inline-credits">
                          <div className="credits-track">
                            {ui.creditLines.map((line) => (
                              <p key={line}>{line}</p>
                            ))}
                          </div>
                        </div>
                      </div>
                    </>
                  ) : null}
                </div>
              </section>
            )}
          </section>
        ) : null}

        {landscapeNotice}
      </main>
    )
  }

  return (
    <main className={`app-shell${isViewportMaximized ? ' viewport-maximized-shell' : ''}`}>
      <section className="experience-grid">
        <div className={`viewport-panel${isViewportMaximized ? ' maximized' : ''}${isDebugMode ? ' debug-mode' : ' play-mode'}`}>
          {isDebugMode ? (
            <div className="viewport-toolbar">
              <div>
                <strong>{activeMap?.originalName ?? ui.debugWaitingForContent}</strong>
                <span>
                  {runtime?.battle
                    ? ui.debugBattleMode(runtime.battle.enemies.length)
                    : activeMap
                      ? ui.debugExploreMode(activeMap.width, activeMap.height)
                      : ui.debugRuntimeNotStarted}
                </span>
                <span className="toolbar-hint">{ui.debugToolbarHint}</span>
              </div>

              <div className="toolbar-actions">
                <div className="debug-map-controls">
                  <label className="sr-only" htmlFor="debug-map-select">
                    {ui.debugJumpToMap}
                  </label>
                  <select
                    id="debug-map-select"
                    className="debug-select"
                    value={debugMapSelection}
                    onChange={(event) => setDebugMapSelection(event.target.value)}
                    disabled={!runtime?.gameStarted || Boolean(overlay)}
                  >
                    <option value="">{ui.debugJumpPlaceholder}</option>
                    {debugMapOptions.map((mapEntry) => (
                      <option key={mapEntry.name} value={mapEntry.name}>
                        {mapEntry.originalName} ({mapEntry.name})
                      </option>
                    ))}
                  </select>
                  <button
                    type="button"
                    className="ghost-button"
                    onClick={() => void jumpToDebugMap()}
                    disabled={!runtime?.gameStarted || !debugMapSelection || Boolean(overlay)}
                  >
                    {ui.debugJump}
                  </button>
                </div>
              </div>
            </div>
          ) : null}

          <div className="viewport-frame">
            {runtime?.gameStarted ? (
              <div className="game-stage" ref={gameStageRef}>
                <canvas
                  ref={canvasRef}
                  width={CANVAS_WIDTH}
                  height={CANVAS_HEIGHT}
                  className="game-canvas"
                  aria-label={ui.canvasAria}
                />

                {battleDuel && battleDuelEnemy && activeBattle ? (
                  <>
                    <section className="battle-fight-panel battle-fight-top-panel" aria-label={ui.battleStatusAria}>
                      <div className="battle-fighter battle-fighter-player">
                        <div className="battle-hit-stack battle-hit-stack-player">
                          <strong className="battle-hit-current">{battleDuel.enemyHitText || '\u00a0'}</strong>
                          <span className="battle-hit-previous">{battleDuel.previousEnemyHitText || '\u00a0'}</span>
                        </div>
                        <div className="battle-portrait-frame">
                          <BattleAvatarIcon avatarId={runtime.player.avatar} spriteSheets={spriteSheets} className="battle-portrait-sprite" />
                        </div>
                      </div>

                      <div className="battle-center-panel">
                        <div className="battle-health-block">
                          <span>{runtime.player.name}</span>
                          <div className="battle-health-track" aria-hidden="true">
                            <div className="battle-health-fill player" style={{ width: `${battlePlayerHpRatio * 100}%` }} />
                          </div>
                        </div>

                        <div className="battle-health-block">
                          <span>{activeBattle.enemyName}</span>
                          <div className="battle-health-track" aria-hidden="true">
                            <div className="battle-health-fill enemy" style={{ width: `${battleEnemyHpRatio * 100}%` }} />
                          </div>
                        </div>
                      </div>

                      <div className="battle-fighter battle-fighter-enemy">
                        <div className="battle-hit-stack battle-hit-stack-enemy">
                          <strong className="battle-hit-current">{battleDuel.playerHitText || '\u00a0'}</strong>
                          <span className="battle-hit-previous">{battleDuel.previousPlayerHitText || '\u00a0'}</span>
                        </div>
                        <div className="battle-portrait-frame">
                          <SpriteIcon tileId={activeBattle.enemySprite} spriteSheets={spriteSheets} className="battle-portrait-sprite" />
                        </div>
                      </div>
                    </section>

                    <section className="battle-fight-panel battle-fight-bottom-panel" aria-label={ui.battleDescriptionAria}>
                      <h2>{activeBattle.enemyName}</h2>
                      {battleActionLines.map((line, index) => (
                        <p key={`battle-action-${activeBattle.enemyName}-${index}`} className="battle-fight-current-line">
                          {line}
                        </p>
                      ))}
                      {battlePreviousActionLines.map((line, index) => (
                        <p key={`battle-action-prev-${activeBattle.enemyName}-${index}`} className="battle-fight-previous-line">
                          {line}
                        </p>
                      ))}
                      {battleDescriptionLines.map((line, index) => (
                        <p key={`${activeBattle.enemyName}-${index}`} className="battle-fight-enemy-note">
                          {line}
                        </p>
                      ))}
                      {battleDuel.allowInventory ? (
                        <div className="battle-fight-footer">
                          <span className="battle-fight-hint">{ui.battleAdvanceHint}</span>
                          <span className="battle-fight-hint battle-fight-hint-secondary">{ui.battleInventoryHint}</span>
                        </div>
                      ) : null}
                    </section>
                  </>
                ) : null}

                {inlineDialogOverlay?.type === 'message' ? (
                  <section
                    ref={inlineDialogPanelRef}
                    className={`inline-dialog-panel interactive`}
                    aria-live="polite"
                    style={dialogPanelStyle}
                    onClick={() => handleMessageOverlayClick()}
                  >
                    <p className="inline-dialog-text">{visibleInlineDialogText}</p>
                    {isBlockingMessageOverlay && isInlineDialogTextFullyVisible && !isLastMessagePage ? (
                      <span className="inline-dialog-marker" aria-hidden="true" />
                    ) : null}
                  </section>
                ) : null}

                {inlineDialogOverlay?.type === 'choice' ? (
                  <>
                    {isInlineDialogTextFullyVisible ? (
                      <section className="inline-choice-box" aria-live="polite" style={choiceBoxStyle}>
                        {inlineDialogOverlay.options.map((option, index) => {
                          const optionNumber = index + 1
                          const isActive = dialogChoiceSelection === optionNumber

                          return (
                            <button
                              key={`${option}-${optionNumber}`}
                              type="button"
                              className={`inline-choice-button${isActive ? ' active' : ''}`}
                              onClick={() => {
                                if (isActive) {
                                  resolveOverlay(optionNumber)
                                  return
                                }

                                setDialogChoiceSelection(optionNumber)
                              }}
                            >
                              <span>{optionNumber}.</span>
                              <strong>{option}</strong>
                            </button>
                          )
                        })}
                      </section>
                    ) : null}
                    <section
                      ref={inlineDialogPanelRef}
                      className="inline-dialog-panel inline-choice-panel"
                      aria-live="polite"
                      style={dialogPanelStyle}
                      onClick={!isInlineDialogTextFullyVisible ? () => revealInlineDialogText() : undefined}
                    >
                      <p className="inline-dialog-text">{visibleInlineDialogText}</p>
                    </section>
                  </>
                ) : null}

                {inlineDialogOverlay?.type === 'textInput' ? (
                  <>
                    {isInlineDialogTextFullyVisible ? (
                      <section className="inline-input-box" aria-live="polite">
                        <label className="inline-text-entry" htmlFor="inline-dialog-input">
                          <span>-&gt;</span>
                          <input
                            id="inline-dialog-input"
                            ref={inlineTextInputRef}
                            className="inline-text-field"
                            value={textInputValue}
                            autoComplete="off"
                            autoCapitalize="characters"
                            maxLength={24}
                            onChange={(event) => setTextInputValue(event.target.value.toUpperCase())}
                            onKeyDown={(event) => {
                              if (event.key === 'Enter') {
                                event.preventDefault()
                                resolveOverlay(textInputValue.toUpperCase())
                              }
                            }}
                          />
                        </label>
                      </section>
                    ) : null}
                    <section
                      ref={inlineDialogPanelRef}
                      className="inline-dialog-panel inline-input-panel"
                      aria-live="polite"
                      style={dialogPanelStyle}
                      onClick={!isInlineDialogTextFullyVisible ? () => revealInlineDialogText() : undefined}
                    >
                      <p className="inline-dialog-text">{visibleInlineDialogText}</p>
                    </section>
                  </>
                ) : null}

                {inlineScreenOverlay?.type === 'inventory' && runtime ? (
                  <section className="main-window-screen inventory-screen" aria-label={ui.inventoryAria}>
                    <div className="main-window-header">
                      <h2>{ui.inventoryTitle}</h2>
                    </div>

                    <div className="inventory-screen-layout">
                      <div className="retro-stat-list">
                        <p>
                          {ui.statStrength}: <strong>{runtime.stats[5] - weaponBonus}</strong>
                          {weaponBonus > 0 ? <span> +{weaponBonus}</span> : null}
                        </p>
                        <p>
                          {ui.statDefense}: <strong>{runtime.stats[6] - armorBonus}</strong>
                          {armorBonus > 0 ? <span> +{armorBonus}</span> : null}
                        </p>
                        <p>
                          {ui.statDexterity}: <strong>{runtime.stats[10] - dexterityBonus}</strong>
                          {dexterityBonus > 0 ? <span> +{dexterityBonus}</span> : null}
                        </p>
                        <p>
                          {ui.statHp}: <strong>{runtime.stats[1]}/{runtime.stats[2]}</strong>
                        </p>
                        <p>
                          {ui.goldLabel}: <strong>{runtime.stats[7]}</strong>
                        </p>
                        <p>
                          {ui.statExp}: <strong>{runtime.stats[3]}</strong>
                        </p>
                        <p className="player-line">
                          <strong>{runtime.player.name}</strong> - {ui.levelLabel} {runtime.stats[4]}
                        </p>
                      </div>

                      <div className="retro-equipment-panel">
                        {ui.equipmentLabels.map(({ slot, label }) => (
                          <div key={slot} className="retro-equipment-row">
                            <span>{label}:</span>
                            <div className="retro-item-box equipment-box">
                              {runtime.inventory[slot]?.imageId ? (
                                <SpriteIcon tileId={runtime.inventory[slot]?.imageId ?? 0} spriteSheets={spriteSheets} className="retro-sprite" />
                              ) : null}
                            </div>
                          </div>
                        ))}
                      </div>

                      <div className="retro-bag-grid" role="grid" aria-label={ui.bagAria}>
                        {Array.from({ length: MAX_BAG_SLOTS }, (_, index) => {
                          const slot = index + 1
                          const item = runtime.inventory[slot]
                          const isActive = inventorySelection === slot

                          return (
                            <button
                              key={slot}
                              type="button"
                              className={`retro-item-box bag-slot${isActive ? ' active' : ''}`}
                              onClick={() => setInventorySelection(slot)}
                              onDoubleClick={() => void applyInventorySelection()}
                            >
                              {item?.imageId ? <SpriteIcon tileId={item.imageId} spriteSheets={spriteSheets} className="retro-sprite" /> : null}
                              {item && item.count > 1 ? <span className="slot-count">{item.count}</span> : null}
                            </button>
                          )
                        })}
                      </div>

                      <div className="retro-item-details">
                        <h3>{selectedInventoryItem?.name ?? ui.emptyItemSlotTitle}</h3>
                        <p>{selectedInventoryDescription}</p>
                      </div>

                    </div>
                  </section>
                ) : null}

                {inlineScreenOverlay?.type === 'journal' && runtime ? (
                  <section className="main-window-screen journal-screen" aria-label={ui.journalAria}>
                    <div className="main-window-header">
                      <h2>{ui.journalTitle}</h2>
                    </div>

                    <div className="journal-screen-body">
                      <div className="journal-paper">
                        <p>{journalText}</p>
                      </div>
                    </div>
                  </section>
                ) : null}

                {(inlineScreenOverlay?.type === 'shopBuy' || inlineScreenOverlay?.type === 'shopSell') && runtime ? (
                  <section
                    className={`main-window-screen shop-screen ${inlineScreenOverlay.type === 'shopBuy' ? 'buy-screen' : 'sell-screen'}`}
                    aria-label={inlineScreenOverlay.type === 'shopBuy' ? ui.buyTitle : ui.sellTitle}
                  >
                    <div className="main-window-header">
                      <h2>{inlineScreenOverlay.type === 'shopBuy' ? ui.buyTitle : ui.sellTitle}</h2>
                      <div className="shop-gold-box" aria-label={ui.goldLabel}>
                        <span>{ui.goldLabel}</span>
                        <strong>{runtime.stats[7]}</strong>
                      </div>
                    </div>

                    <div className="shop-screen-layout">
                      <div className="shop-prompt-box">
                        <p>{shopPromptText}</p>
                      </div>

                      {shopNoticeText ? (
                        <div className="shop-notice-box" aria-live="polite">
                          <p>{shopNoticeText}</p>
                        </div>
                      ) : null}

                      {selectedShopEntry ? (
                        <>
                          <div className="shop-focus-panel">
                            <div className="retro-item-box shop-focus-icon">
                              {selectedShopEntry.item.imageId ? (
                                <SpriteIcon
                                  tileId={selectedShopEntry.item.imageId}
                                  spriteSheets={spriteSheets}
                                  className="retro-sprite"
                                />
                              ) : null}
                              {selectedShopEntry.item.count > 1 ? (
                                <span className="slot-count">{ui.shopCountPrefix}{selectedShopEntry.item.count}</span>
                              ) : null}
                            </div>

                            <div className="retro-item-details shop-item-details">
                              <h3>{selectedShopEntry.label}</h3>
                              <p>{selectedShopDescription}</p>
                            </div>
                          </div>

                          <div className="shop-price-box" aria-label={ui.priceLabel}>
                            <span>{ui.priceLabel}</span>
                            <strong>{selectedShopEntry.price} {ui.goldLabel}</strong>
                          </div>

                          <div className="shop-carousel" role="list" aria-label={ui.selectionLabel}>
                            {shopCarouselIndices.map((entryIndex) => {
                              const entry = shopEntries[entryIndex]
                              const isActive = entryIndex === selectedShopIndex

                              if (!entry) {
                                return null
                              }

                              return (
                                <button
                                  key={`${entry.key}-${entryIndex}`}
                                  type="button"
                                  className={`shop-carousel-slot${isActive ? ' active' : ''}`}
                                  onClick={() => setShopSelection(entryIndex)}
                                  onDoubleClick={() => resolveOverlay(entry.actionValue)}
                                >
                                  <div className="retro-item-box shop-carousel-icon">
                                    {entry.item.imageId ? (
                                      <SpriteIcon tileId={entry.item.imageId} spriteSheets={spriteSheets} className="retro-sprite" />
                                    ) : null}
                                    {entry.item.count > 1 ? <span className="slot-count">{ui.shopCountPrefix}{entry.item.count}</span> : null}
                                  </div>
                                  <strong>{entry.label}</strong>
                                </button>
                              )
                            })}
                          </div>
                        </>
                      ) : (
                        <div className="shop-empty-panel">
                          <p>{ui.noMatchingItems}</p>
                        </div>
                      )}
                    </div>
                  </section>
                ) : null}

                {inlineScreenOverlay?.type === 'mapView' && runtime ? (
                  <section className="main-window-screen mapview-screen" aria-label={ui.mapAria}>
                    <div className="main-window-header">
                      <h2>{ui.mapTitle}</h2>
                    </div>

                    <div className="map-screen-body">
                      <div className="map-screen-frame">
                        <canvas ref={mapCanvasRef} className="map-canvas inline-map-canvas" aria-label={ui.mapCanvasAria} />
                      </div>
                    </div>
                  </section>
                ) : null}

                {inlineScreenOverlay?.type === 'credits' ? (
                  <section className="main-window-screen credits-inline-screen" aria-label={ui.creditsAria}>
                    <div className="main-window-header">
                      <h2>{ui.creditsTitle}</h2>
                    </div>

                    <div className="credits-inline-body">
                      <div className="credits-list inline-credits-list">
                        {inlineScreenOverlay.lines.map((line) => (
                          <p key={line}>{line}</p>
                        ))}
                      </div>
                    </div>
                  </section>
                ) : null}
              </div>
            ) : (
              <div className="start-card">
                <h2>{ui.startCardTitle}</h2>
                <p>{ui.startCardBody}</p>

                <label className="field-label" htmlFor="player-name">
                  {ui.nameLabel}
                </label>
                <input
                  id="player-name"
                  className="text-field"
                  value={startName}
                  onChange={(event) => setStartName(event.target.value)}
                  maxLength={18}
                />

                <div className="avatar-picker">
                  {ui.avatarOptions.map((avatar) => (
                    <button
                      key={avatar.id}
                      type="button"
                      className={`avatar-button${startAvatar === avatar.id ? ' active' : ''}`}
                      onClick={() => setStartAvatar(avatar.id)}
                    >
                      <span className="avatar-button-content">
                        <AvatarPreview
                          avatarId={avatar.id}
                          spriteSheets={spriteSheets}
                          frame={frontAnimationTick}
                          className="avatar-preview-canvas"
                        />
                        <span className="avatar-label">{avatar.name}</span>
                      </span>
                    </button>
                  ))}
                </div>

                <button
                  type="button"
                  className="primary-button start-button"
                  onClick={() => {
                    void startNewGame()
                  }}
                  disabled={!contentRef.current}
                >
                  {ui.startGoldAdventure}
                </button>
              </div>
            )}

          </div>

          {showMobileControls ? (
            <section className="mobile-controls" aria-label={ui.mobileControlsAria}>
              {fullscreenSupported ? (
                <button
                  type="button"
                  className="mobile-control-button mobile-fullscreen-button"
                  onClick={() => void toggleFullscreen()}
                  disabled={mobileControlButtonsDisabled}
                  aria-label={ui.fullscreenAria}
                  title={ui.fullscreenAria}
                >
                  ⛶
                </button>
              ) : null}

              <div className="mobile-dpad" role="group" aria-label={ui.movementControlsAria}>
                <span className="mobile-dpad-spacer" aria-hidden="true" />
                <button
                  type="button"
                  className="mobile-control-button mobile-direction-button"
                  onClick={() => handleDirectionalInput('up')}
                  disabled={mobileControlButtonsDisabled}
                  aria-label={ui.moveUpAria}
                >
                  ▲
                </button>
                <span className="mobile-dpad-spacer" aria-hidden="true" />
                <button
                  type="button"
                  className="mobile-control-button mobile-direction-button"
                  onClick={() => handleDirectionalInput('left')}
                  disabled={mobileControlButtonsDisabled}
                  aria-label={ui.moveLeftAria}
                >
                  ◀
                </button>
                <button
                  type="button"
                  className="mobile-control-button mobile-action-button"
                  onClick={() => handleConfirmInput({ allowTextSubmit: true })}
                  disabled={mobileControlButtonsDisabled}
                  aria-label={ui.actionAria}
                >
                  {ui.actionButton}
                </button>
                <button
                  type="button"
                  className="mobile-control-button mobile-direction-button"
                  onClick={() => handleDirectionalInput('right')}
                  disabled={mobileControlButtonsDisabled}
                  aria-label={ui.moveRightAria}
                >
                  ▶
                </button>
                <span className="mobile-dpad-spacer" aria-hidden="true" />
                <button
                  type="button"
                  className="mobile-control-button mobile-direction-button"
                  onClick={() => handleDirectionalInput('down')}
                  disabled={mobileControlButtonsDisabled}
                  aria-label={ui.moveDownAria}
                >
                  ▼
                </button>
                <span className="mobile-dpad-spacer" aria-hidden="true" />
              </div>

              <div className="mobile-utility-grid" role="group" aria-label={ui.shortcutsAria}>
                <button
                  type="button"
                  className="mobile-control-button mobile-utility-button"
                  onClick={() => handleBackInput()}
                  disabled={mobileControlButtonsDisabled}
                >
                  {ui.backButton}
                </button>
                <button
                  type="button"
                  className="mobile-control-button mobile-utility-button"
                  onClick={() => handleBagShortcut()}
                  disabled={mobileControlButtonsDisabled}
                >
                  {ui.bagButton}
                </button>
                <button
                  type="button"
                  className="mobile-control-button mobile-utility-button"
                  onClick={() => handleJournalShortcut()}
                  disabled={mobileControlButtonsDisabled}
                >
                  {ui.journalButton}
                </button>
                <button
                  type="button"
                  className="mobile-control-button mobile-utility-button"
                  onClick={() => handleSaveShortcut()}
                  disabled={mobileControlButtonsDisabled}
                >
                  {ui.saveButton}
                </button>
              </div>
            </section>
          ) : null}
        </div>
      </section>

        {modalOverlay ? (
          <div className={`overlay-backdrop${modalOverlay.type === 'fade' ? ' fade-only' : ''}`}>
            {modalOverlay.type === 'fade' ? (
              <div
              className={`fade-screen ${modalOverlay.mode}`}
              style={
                modalOverlay.durationMs
                  ? ({
                      '--fade-duration': `${modalOverlay.durationMs}ms`,
                    } as CSSProperties)
                  : undefined
              }
            />
            ) : null}
          </div>
        ) : null}

        {landscapeNotice}
      </main>
    )
  }

function sleep(ms: number) {
  return new Promise<void>((resolve) => {
    window.setTimeout(resolve, ms)
  })
}

export default App
