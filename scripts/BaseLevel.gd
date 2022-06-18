extends Node2D

const SMF = preload('res://addons/midi/SMF.gd')
const MP = preload('res://addons/midi/MidiPlayer.gd')

export(String, FILE, '*.mid') var file_uri: String = '' setget set_file_name

signal eigth_beat_event(beat)

onready var midiPlayer = $AudioStreamPlayer/GodotMIDIPlayer
var beat = {'measure': 1, 'beat': 1, 'eighth':1}

const EDITED_MIDI_DIR = 'res://midi/edited/'

onready var player_ani_tree = $Player/AnimationTree
onready var player_ani_player = $Player/AnimationPlayer


func set_file_name(path: String):
#	file_uri = path
	var path_slash_split = path.split('/')
	var file_name = path_slash_split[path_slash_split.size() - 1]
	if !File.new().file_exists(EDITED_MIDI_DIR + file_name):
		file_uri = _create_midi_file_with_beat_events(path)
		print('asdfgh')
		print(file_uri)
	else:
		file_uri = EDITED_MIDI_DIR + file_name
	

# Called when the node enters the scene tree for the first time.
func _ready():
	print('yeeer')
	print('tempo: {tempo}'.format({ 'tempo': midiPlayer.tempo }))
	
	midiPlayer.file = file_uri
	var smf_data = SMF.new().read_file(file_uri)
	print(smf_data.tracks[smf_data.track_count - 1].events[0].time)
	print(smf_data.tracks[smf_data.track_count - 1].events[0].event.args)
	print(smf_data.tracks[smf_data.track_count - 1].events[1].time)
	print(smf_data.tracks[smf_data.track_count - 1].events[1].event.args)
	print(smf_data.tracks[smf_data.track_count - 1].events[2].time)
	print(smf_data.tracks[smf_data.track_count - 1].events[2].event.args)
	
	var animation_state_mode: AnimationNodeStateMachinePlayback = (
		player_ani_tree.get("parameters/playback")
	)
	player_ani_tree.set(
		"parameters/idle/TimeScale/scale",
		player_ani_player.get_animation("idle").length / (60 / midiPlayer.tempo)
	)
	animation_state_mode.stop()
	
	midiPlayer.play()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	print(midiPlayer.position)
#	pass
#	print((midiPlayer.position / midiPlayer.last_position) * 100)
	pass


func _create_midi_file_with_beat_events(midi_file_uri: String) -> String:
	var time_signatures = []
	var max_time = 0
	var smf_data = SMF.new().read_file(midi_file_uri)
	
	for track in smf_data.tracks:
		if track.events[track.events.size() - 1].time > max_time:
			max_time = track.events[track.events.size() - 1].time

		for event_chunk in track.events:
			if (
				event_chunk.event.type == SMF.MIDIEventType.system_event
				and event_chunk.event.args.type == SMF.MIDISystemEventType.beateat
			):
				time_signatures.append(event_chunk)
				
	time_signatures.sort_custom(SMF.TrackEventSorter, 'sort')
	print(time_signatures)
	print(max_time)
	var ts_index = 0
	
	var midi_file = File.new()
	midi_file.open(midi_file_uri, File.READ)
	var file_buffer = midi_file.get_buffer(midi_file.get_len())
	
	# [time, status, status, len, ...text("8th")]
	var enote_event = [smf_data.timebase / 2, 0xFF, 0x01, 0x03, 0x38, 0x74, 0x68]
	
	# [chunk_type(0-3), len(4-7), format(8-9), tracks(10-11), tpn(12-13)]
	var header_chunk = file_buffer.subarray(0, 13)
	
	var track_chunk_type = [0x4D, 0x54, 0x72, 0x6B] # MTrk
	var track_len = file_buffer.subarray(18, 21)
	print(header_chunk)
	print(track_chunk_type)
	
	print(enote_event)
	print(enote_event.slice(1, -1))
	print(_int_to_byte_array(1000, 4))
	
	var enote_event_sequence = []
	# start first event at tick 0
	enote_event_sequence.append(0x00)
	enote_event_sequence.append_array(enote_event.slice(1, -1))

	var time_tracker = 0
	while time_tracker < max_time:
		enote_event_sequence.append_array(enote_event)
		time_tracker += smf_data.timebase / 2
	# add end of track event
	enote_event_sequence.append_array([smf_data.timebase / 2, 0xFF, 0x2F, 0x00])
	
	var new_track = []
	new_track.append_array(track_chunk_type)
	new_track.append_array(_int_to_byte_array(enote_event_sequence.size(), 4))
	new_track.append_array(enote_event_sequence)
	
	var updated_file_buffer = file_buffer.subarray(0, -1)
	# make sure format is 1 (mutiple tracks)
	updated_file_buffer[8] = 0x00
	updated_file_buffer[9] = 0x01
	
	var num_of_tracks = _int_to_byte_array(smf_data.track_count + 1, 2)
	updated_file_buffer[10] = num_of_tracks[0]
	updated_file_buffer[11] = num_of_tracks[1]
	
	updated_file_buffer.append_array(new_track)
	
	midi_file.close()
	
	var updated_midi_file = File.new()
	var path_slash_split = midi_file_uri.split('/')
	var midi_file_name = path_slash_split[path_slash_split.size() - 1]
	updated_midi_file.open(EDITED_MIDI_DIR + midi_file_name, File.WRITE)
	updated_midi_file.store_buffer(updated_file_buffer)
	updated_midi_file.close()
	print('file created')
	
	return EDITED_MIDI_DIR + midi_file_name


func _int_to_byte_array(value: int, byte_length = null):
	var hex = '%X' % value
	if hex.length() % 2 == 1:
		hex = '0' + hex
		
	var byte_arr = []
	while hex.length() > 0:
		var hex_byte = '0x%s' % hex.substr(0, 2)
		byte_arr.append(hex_byte.hex_to_int())
		hex = hex.substr(2)
	
	if byte_length != null:
		while byte_arr.size() != byte_length:
			byte_arr.push_front(0x00)
	
	return byte_arr


func _on_GodotMIDIPlayer_midi_event(
	channel: MP.GodotMIDIPlayerChannelStatus,
	event: SMF.MIDIEvent
):
	var eventString = ''
	match event.type:
		SMF.MIDIEventType.note_off:
			eventString = 'NoteOff %d' % event.note
		SMF.MIDIEventType.note_on:
			eventString = 'NoteOn note[%d] velocity[%d]' % [ event.note, event.velocity ]
		SMF.MIDIEventType.polyphonic_key_pressure:
			eventString = 'PolyphonicKeyPressure note[%d] value[%d]' % [ event.note, event.value ] 
		SMF.MIDIEventType.control_change:
			eventString = 'ControlChange number[%d] value[%d]' % [ event.number, event.value ]
		SMF.MIDIEventType.program_change:
			eventString = 'ProgramChange #%d' % event.number
		SMF.MIDIEventType.pitch_bend:
			eventString = 'PitchBend %d -> %f' % [ event.value, ( event.value / 8192.0 ) - 1.0 ]
		SMF.MIDIEventType.channel_pressure:
			eventString = 'ChannelPressure %d' % event.value
		SMF.MIDIEventType.system_event:
			eventString = 'SystemEvent %d' % event.args.type
			if (
				event.args.type == SMF.MIDISystemEventType.text_event
				and event.args.text == '8th'
			):
				self.emit_signal('eigth_beat_event', beat)
				print('channel: {0}, event: {1}, beat: {2}'.format([channel.number, eventString, beat]))
#				print(event.args)
				beat.eighth += 1
				if beat.eighth > 2:
					beat.eighth = 1
					beat.beat += 1
				if beat.beat > 4:
					beat.beat = 1
					beat.measure += 1

				var animation_state_mode: AnimationNodeStateMachinePlayback = (
					player_ani_tree.get("parameters/playback")
				)
				if not animation_state_mode.is_playing():
#					pass
					animation_state_mode.start("idle")
				
				pass
#	print('channel: {0}, event: {1}'.format([channel.number, eventString]))
