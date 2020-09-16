extends Node


export(NodePath) var START_STATE #export makes variable part of scene it is called in and editable in the editor
var states_map = {} #stores all possible state nodes

var states_stack = [] #stores current states for push automaton
var current_state = null
var _active = false setget set_active


func _ready():
	for child in get_children():
		child.connect("finished", self, "_change_state")
	initialize(START_STATE)


func initialize(start_state): #called in ready, state_machine is only active if called by a script
	set_active(true)
	states_stack.push_front(get_node(start_state))
	current_state = states_stack[0]
	current_state.enter()
	

func set_active(value): #sets state machine active in initialize method
	_active = value
	set_physics_process(value)
	set_process_input(value)
	if not _active:
		states_stack = []
		current_state = null


func _input(event):
	current_state.handle_input(event)


func _ai_input(input):
	current_state.handle_ai_input(input)


func _physics_process(delta):
	current_state.update(delta)


func _on_animation_finished(anim_name):
	if not _active:
		return
	current_state._on_animation_finished(anim_name)


func _change_state(state_name):
	if not _active:
		return
	current_state.exit() #runs exit method for current state to clean up values
	
	if state_name == "previous": #code for push automaton; pops state off top of stack if necessary
		states_stack.pop_front()
	else: #change state to state_name otherwise
		states_stack[0] = states_map[state_name] #place new state at top of state stack array
	
	current_state = states_stack[0]
	
	#New State Initialization
	current_state.enter() #always reinitialize a new state
#	if state_name != 'previous': #only reinitialize the state if placing a new state on top of the state stack
#		current_state.enter()

