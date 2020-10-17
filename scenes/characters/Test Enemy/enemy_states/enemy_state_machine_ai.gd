extends "res://scripts/State Machine/state_machine.gd"


signal ai_state_changed(move_state)
signal ai_state_stack_changed(state_stack)
signal initialized_values_dic_set(init_values_dic)


var initialized_values = {
	#Input
	"input": {},
	"input_current": {},
	"input_previous": {},
	
	#AI Flags
	"advancing": false,
	"suspicious": false,
	"targetting": false,
	
	#Pathfinding Variables
	"route": [],
	"path": [],
	"path_point": 0,
	
	#Targetting Variables
	"focus_object": null,
	"targettable_objects":  [],
	"visible_targets":  [],
	"closest_target": null,
	"head_position": Vector3(0,0,0),
	"target_position": Vector3(0,0,0),
	"target_direction": Vector3(0,0,0),
	"seek_target_pos_last": Vector3(0,0,0),
}


func _ready():
	states_map = {
		"idle": $Idle,
		"engage": $Engage,
	}
	#Send out dictionary of initialized values to all states at start
	emit_signal("initialized_values_dic_set", initialized_values)
	
	emit_signal("ai_state_changed", states_stack[0].name)
	emit_signal("ai_state_stack_changed", states_stack)


func _process(delta):
	current_state.handle_ai_input()


func _change_state(state_name): #state_machine.gd does the generalized work
	if not _active:
		return
	
	##State variable initialization (all states are initialized)
	if !(state_name in ["previous"]):
		#Set initialized values in old state for transfer
		current_state.set_initialized_values(current_state.initialized_values)
		#Transfer initialized values to new state
		states_map[state_name].initialize(current_state.initialized_values) #initialize velocity for certain states out of walk state
	
	##Special new state handling
		
	##Stack states that stack
		
	##Previous State initialization
	if state_name in ["previous"]:
		#Set initialized values in old state for transfer
		current_state.set_initialized_values(current_state.initialized_values)
		#Transfer initialized values to new state
		states_stack[1].initialize(current_state.initialized_values) #pass current state velocity to previous state if switching to previous state
	
	##State Change
	._change_state(state_name)
	
	#Send out dictionary of initialized values for states that don't initialize
	emit_signal("initialized_values_dic_set", initialized_values)
	
	emit_signal("ai_state_changed", states_stack[0].name)
	emit_signal("ai_state_stack_changed", states_stack)


func _input(_event): #only for handling input that can interrupt other states i.e. something that interrupts jumping
	return










