extends Label


func _ready():
	set_process(true)
	
func _process(_delta):
	self.text = 'FPS: ' + str(Engine.get_frames_per_second())
