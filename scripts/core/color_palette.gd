class_name GameColors
extends Node

var FONT: FontFile
var FONT_BOLD: FontFile

var COLOR_ATTACK = Color("#E8294A")
var COLOR_DEFENSE = Color("#3D4CE8")
var COLOR_MODIFIER = Color("#7B2FE8")
var COLOR_HAZARD = Color("#111111")
var COLOR_BACKGROUND = Color("#0F0F12")
var COLOR_WHITE = Color("#FFFFFF")
var COLOR_SALT = Color("#F5C842")
var COLOR_CRASH = Color("#E8294A")

static var RARITY_COMMON    = Color("#666666")
static var RARITY_UNCOMMON  = Color("#2D9E2D")
static var RARITY_RARE      = Color("#1A6ECF")
static var RARITY_EPIC      = Color("#7B2FBF")
static var RARITY_LEGENDARY = Color("#CF7A1A")

static var GLOW_PROVOCATION = Color("#FFD900")
static var GLOW_RAMPART     = Color("#FFD900")

static var UI_HP      = Color("#41FF1A")
static var UI_DAMAGE  = Color("#FF6464")
static var UI_DEFENSE = Color("#4FA3FF")

func _ready() -> void:
	FONT = load("res://font/LondrinaSolid-Regular.ttf")
	FONT_BOLD = load("res://font/LondrinaSolid-Black.ttf")
