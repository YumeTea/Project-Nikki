extends "res://scripts/State Machine/state_machine.gd"


signal initialized_values_dic_set(init_values_dic)


var initialized_values = {
	"velocity": Vector3(0,0,0),
	"focus_target_pos": null,
	"cast_jump": false,
	"is_walking": false,
	"left_joystick_axis": Vector2(0,0),
	"right_joystick_axis": Vector2(0,0),
	"input": {}
}



func _ready():
	states_map = {
	"idle": $Idle,
	"walk": $Walk,
	"fall": $Fall,
	"jump": $Jump,
	"ground_cast": $Ground_Cast,
	"air_cast": $Air_Cast,
	"death": $Death,
	"void": $Void
}
	#Connect state machine to ai input
	owner.connect("ai_input_changed", self, "_ai_input")
	#Send dictionary of initialized values to all states
	emit_signal("initialized_values_dic_set", initialized_values)


func _change_state(state_name): #state_machine.gd does the generalized work
	if not _active:
		return
	##States that stack get put on top of the state stack
	if state_name in ["fall", "jump", "ground_cast", "air_cast"]: #code for push automaton; "pushes" state_name onto top of state stack
		states_stack.push_front(states_map[state_name])
	##New State initialization (excludes idle for some reason)
	if state_name in ["walk", "fall", "jump", "ground_cast", "air_cast", "voided"]:
		#Set initialized values in old state for transfer
		current_state.set_initialized_values(current_state.initialized_values)
		#Transfer initialized values to new state
		states_map[state_name].initialize(current_state.initialized_values) #initialize velocity for certain states out of walk state
	##Jumping/Falling during Ground Cast
	if state_name in ["jump", "fall"] and current_state in [$Ground_Cast]:
		states_stack.pop_front()
	##Going from Air Cast to Ground Cast
	if state_name in ["ground_cast"] and current_state in [$Air_Cast]:
		states_stack.pop_front()
		states_stack.pop_front()
		states_stack.pop_front()
		states_stack.push_front(states_map[state_name])
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
	
#	print("npc current state: " + str(current_state.get_name()))


func _input(_event): #only for handling input that can interrupt other states i.e. something that interrupts jumping
	return


func _ai_input(input):
	._ai_input(input)

