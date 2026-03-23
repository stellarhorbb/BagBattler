class_name ShellResource
extends Resource

enum ShellType { DARK, STRIPED, NACRE, BROKEN }

@export var shell_type: ShellType = ShellType.DARK
@export var shell_name: String = ""
@export var flavor_text: String = ""
@export var cost: int = 10
