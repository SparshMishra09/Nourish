enum ExerciseMotion {
  pushUp,
  inclinePushUp,
  pikePushUp,
  dumbbellRow,
  shoulderPress,
  proneSweep,
  deadBug,
  squat,
  hipHinge,
  singleLegHinge,
  reverseLunge,
  bridge,
  calfRaise,
  sidePlank,
  shoulderTap,
  mountainClimber,
  standingClimber,
  fastFeet,
  stepJack,
  kneeDrive,
  powerMarch,
  lateralReach,
  birdDog,
  hipSwitch,
  childPose,
  worldStretch,
  standingFlow,
}

class ExerciseGuide {
  const ExerciseGuide({
    required this.motion,
    required this.setup,
    required this.action,
    required this.breathing,
    required this.cues,
    required this.avoid,
  });

  final ExerciseMotion motion;
  final String setup;
  final String action;
  final String breathing;
  final List<String> cues;
  final String avoid;
}

class ExerciseGuideCatalog {
  const ExerciseGuideCatalog._();

  static ExerciseGuide? forName(String exerciseName) => _guides[exerciseName];

  static Set<String> get coveredExerciseNames => _guides.keys.toSet();
}

const _guides = <String, ExerciseGuide>{
  'Push-up': ExerciseGuide(
    motion: ExerciseMotion.pushUp,
    setup: 'Hands just outside shoulder width, legs long, body in one line.',
    action: 'Lower your chest between your hands, then press the floor away.',
    breathing: 'Inhale down · exhale as you press.',
    cues: ['Brace your middle', 'Elbows about 45°', 'Move as one unit'],
    avoid: 'Do not let the hips sag or crane the chin toward the floor.',
  ),
  'One-arm dumbbell row': ExerciseGuide(
    motion: ExerciseMotion.dumbbellRow,
    setup:
        'Hinge with a flat back and support your free hand on a firm surface.',
    action:
        'Pull the dumbbell toward your back pocket, pause, then lower fully.',
    breathing: 'Exhale on the pull · inhale on the lower.',
    cues: ['Shoulder away from ear', 'Elbow close', 'Square your hips'],
    avoid: 'Do not twist the torso or jerk the weight from the floor.',
  ),
  'Dumbbell shoulder press': ExerciseGuide(
    motion: ExerciseMotion.shoulderPress,
    setup: 'Stand tall with dumbbells at shoulder height and ribs stacked.',
    action: 'Press overhead until the arms are long, then return with control.',
    breathing: 'Exhale up · inhale down.',
    cues: ['Squeeze glutes', 'Wrists over elbows', 'Finish over shoulders'],
    avoid: 'Do not lean back or flare the ribs to move the weight.',
  ),
  'Close-grip push-up': ExerciseGuide(
    motion: ExerciseMotion.pushUp,
    setup:
        'Place hands beneath the shoulders and keep elbows close to your ribs.',
    action: 'Lower as one straight line, then press through the whole palm.',
    breathing: 'Inhale down · exhale up.',
    cues: ['Narrow elbows', 'Firm plank', 'Full palm pressure'],
    avoid: 'Do not force a diamond hand shape if it irritates your wrists.',
  ),
  'Reverse snow angel': ExerciseGuide(
    motion: ExerciseMotion.proneSweep,
    setup:
        'Lie face down, lightly brace your core and float the hands off the floor.',
    action: 'Sweep straight arms from your hips to overhead and slowly return.',
    breathing: 'Breathe slowly and keep the neck relaxed.',
    cues: ['Thumbs up', 'Reach long', 'Small clean range'],
    avoid: 'Do not lift the ribs or shrug the shoulders toward the ears.',
  ),
  'Dead bug': ExerciseGuide(
    motion: ExerciseMotion.deadBug,
    setup:
        'Lie on your back with hips and knees at 90° and arms above shoulders.',
    action: 'Extend opposite arm and leg without letting your lower back lift.',
    breathing: 'Long exhale as limbs extend · inhale to reset.',
    cues: ['Back gently heavy', 'Move opposite limbs', 'Go slowly'],
    avoid: 'Shorten the range before allowing the back to arch.',
  ),
  'Dumbbell goblet squat': ExerciseGuide(
    motion: ExerciseMotion.squat,
    setup:
        'Hold one dumbbell at your chest, feet comfortable and toes slightly out.',
    action:
        'Sit between your hips, keep the chest proud, then drive the floor away.',
    breathing: 'Inhale and brace down · exhale through the stand.',
    cues: ['Knees track toes', 'Whole foot down', 'Tall finish'],
    avoid: 'Do not let the heels lift or the knees collapse inward.',
  ),
  'Dumbbell Romanian deadlift': ExerciseGuide(
    motion: ExerciseMotion.hipHinge,
    setup: 'Hold dumbbells by your thighs with soft knees and a long spine.',
    action:
        'Push hips back until hamstrings load, then squeeze glutes to stand.',
    breathing: 'Inhale on the hinge · exhale as you stand.',
    cues: ['Weights skim legs', 'Hips travel back', 'Neck stays long'],
    avoid: 'Do not turn the hinge into a squat or round toward the floor.',
  ),
  'Reverse lunge': ExerciseGuide(
    motion: ExerciseMotion.reverseLunge,
    setup: 'Stand tall with feet under hips and brace before stepping.',
    action:
        'Step one foot back, lower both knees, then push through the front foot.',
    breathing: 'Inhale down · exhale to return.',
    cues: ['Front heel heavy', 'Back knee under hip', 'Torso tall'],
    avoid: 'Do not place both feet on one tight line like a balance beam.',
  ),
  'Glute bridge': ExerciseGuide(
    motion: ExerciseMotion.bridge,
    setup:
        'Lie on your back, knees bent and heels a comfortable reach from your hips.',
    action: 'Tuck the pelvis slightly, lift the hips, pause, and lower slowly.',
    breathing: 'Exhale up · inhale down.',
    cues: ['Drive through heels', 'Ribs stay down', 'Squeeze at the top'],
    avoid: 'Do not overarch the lower back to chase extra height.',
  ),
  'Calf raise': ExerciseGuide(
    motion: ExerciseMotion.calfRaise,
    setup: 'Stand tall with feet parallel and use light support for balance.',
    action:
        'Rise onto the balls of both feet, pause high, then lower completely.',
    breathing: 'Exhale up · inhale on the slow lower.',
    cues: ['Press big toes down', 'Ankles stay straight', 'Full range'],
    avoid: 'Do not bounce or let the ankles roll outward.',
  ),
  'Side plank': ExerciseGuide(
    motion: ExerciseMotion.sidePlank,
    setup: 'Place elbow below shoulder and stack or stagger your feet.',
    action: 'Lift your hips until ear, shoulder, hip and ankle form one line.',
    breathing: 'Take quiet breaths without losing the brace.',
    cues: ['Push floor away', 'Hips forward', 'Long straight line'],
    avoid: 'Do not sink into the supporting shoulder.',
  ),
  'Plank shoulder tap': ExerciseGuide(
    motion: ExerciseMotion.shoulderTap,
    setup: 'Use a high plank with feet wider than hips for a stable base.',
    action:
        'Tap the opposite shoulder with one hand, replace it, then alternate.',
    breathing: 'Exhale with each tap.',
    cues: ['Quiet hips', 'Press support hand', 'Slow alternation'],
    avoid: 'Do not rotate the pelvis from side to side.',
  ),
  'Tempo bodyweight squat': ExerciseGuide(
    motion: ExerciseMotion.squat,
    setup: 'Set feet comfortably, brace, and reach arms forward for balance.',
    action: 'Lower for three seconds, pause briefly, then stand with control.',
    breathing: 'Inhale through the descent · exhale to stand.',
    cues: ['Count the tempo', 'Knees track toes', 'Whole foot grounded'],
    avoid: 'Do not drop quickly through the final part of the descent.',
  ),
  'Prone Y-T-W raises': ExerciseGuide(
    motion: ExerciseMotion.proneSweep,
    setup: 'Lie face down with forehead supported and hands hovering.',
    action: 'Lift into a Y, then T, then bent-elbow W; reset between shapes.',
    breathing: 'Exhale on each lift · inhale on each reset.',
    cues: ['Thumbs point up', 'Shoulders stay low', 'Use tiny ranges'],
    avoid: 'Do not throw the arms upward or arch the lower back.',
  ),
  'Single-leg hip hinge': ExerciseGuide(
    motion: ExerciseMotion.singleLegHinge,
    setup:
        'Balance on one soft knee with hips square and arms reaching forward.',
    action:
        'Send the free leg back as your torso tips forward, then return tall.',
    breathing: 'Inhale into the hinge · exhale to stand.',
    cues: ['Back leg stays long', 'Square hip bones', 'Move like a seesaw'],
    avoid: 'Do not open the free hip toward the ceiling.',
  ),
  'Pike push-up': ExerciseGuide(
    motion: ExerciseMotion.pikePushUp,
    setup: 'Start in an inverted V with hips high and hands shoulder width.',
    action:
        'Bend elbows and lower the crown ahead of your hands, then press away.',
    breathing: 'Inhale down · exhale as you press.',
    cues: ['Hips stay high', 'Head travels forward', 'Elbows angle back'],
    avoid: 'Do not lower straight between the hands or collapse the neck.',
  ),
  'Mountain climber': ExerciseGuide(
    motion: ExerciseMotion.mountainClimber,
    setup: 'Begin in a strong high plank with shoulders above wrists.',
    action:
        'Drive one knee toward the chest, switch feet, and keep the torso quiet.',
    breathing: 'Use short, steady breaths throughout.',
    cues: ['Push the floor', 'Quick light feet', 'Hips level'],
    avoid: 'Do not bounce the hips high or land heavily on the toes.',
  ),
  'Boxer shuffle': ExerciseGuide(
    motion: ExerciseMotion.fastFeet,
    setup:
        'Stand light on the balls of your feet with soft knees and relaxed hands.',
    action: 'Shift weight left and right in a small, quick rhythm.',
    breathing: 'Relax your jaw and breathe continuously.',
    cues: ['Stay springy', 'Tiny contacts', 'Shoulders relaxed'],
    avoid: 'Do not lock the knees or stamp the heels.',
  ),
  'Fast feet': ExerciseGuide(
    motion: ExerciseMotion.fastFeet,
    setup: 'Use an athletic stance with hips back slightly and arms ready.',
    action:
        'Alternate rapid, low foot lifts while staying in one compact space.',
    breathing: 'Keep a quick, even breathing rhythm.',
    cues: ['Feet under hips', 'Quiet contacts', 'Chest steady'],
    avoid: 'Do not stand upright and pound the floor.',
  ),
  'Knee drive': ExerciseGuide(
    motion: ExerciseMotion.kneeDrive,
    setup: 'Take a short split stance with weight mostly over the front foot.',
    action:
        'Drive the back knee forward and up as the arms pull down, then reset.',
    breathing: 'Exhale on each drive.',
    cues: ['Push front foot', 'Knee toward chest', 'Finish tall'],
    avoid: 'Do not lean far backward at the top.',
  ),
  'Lateral step & reach': ExerciseGuide(
    motion: ExerciseMotion.lateralReach,
    setup: 'Stand with soft knees and enough clear space on both sides.',
    action:
        'Step wide, sit into that hip and reach across; return and alternate.',
    breathing: 'Exhale into each reach.',
    cues: ['Hips move back', 'Trail leg long', 'Reach across'],
    avoid: 'Do not let the working knee collapse inward.',
  ),
  'Power march': ExerciseGuide(
    motion: ExerciseMotion.powerMarch,
    setup: 'Stand tall with elbows bent and ribs stacked over hips.',
    action: 'Drive opposite knee and arm upward, then switch with intent.',
    breathing: 'Exhale on each strong knee drive.',
    cues: ['Opposite arm and leg', 'Tall posture', 'Strong foot strike'],
    avoid: 'Do not lean back or rush beyond your balance.',
  ),
  'Standing mountain climber': ExerciseGuide(
    motion: ExerciseMotion.standingClimber,
    setup: 'Stand tall with arms reaching overhead and feet under hips.',
    action: 'Pull one elbow toward the opposite rising knee, then alternate.',
    breathing: 'Exhale on every cross-body pull.',
    cues: ['Rotate through ribs', 'Knee comes high', 'Return fully'],
    avoid: 'Do not yank the neck or collapse the chest.',
  ),
  'Step jack': ExerciseGuide(
    motion: ExerciseMotion.stepJack,
    setup: 'Stand with feet together and hands resting by your sides.',
    action:
        'Step one foot wide as arms arc overhead, return, then switch sides.',
    breathing: 'Inhale open · exhale closed.',
    cues: ['Soft knees', 'Full arm arc', 'Alternate sides'],
    avoid: 'Do not slam the stepping foot or shrug at the top.',
  ),
  'Squat to reach': ExerciseGuide(
    motion: ExerciseMotion.squat,
    setup: 'Stand with feet comfortable and hands near the chest.',
    action: 'Squat down, then stand and reach both arms long overhead.',
    breathing: 'Inhale down · exhale into the reach.',
    cues: ['Sit between hips', 'Drive through feet', 'Reach tall'],
    avoid: 'Do not arch the back during the overhead reach.',
  ),
  'Marching bridge': ExerciseGuide(
    motion: ExerciseMotion.bridge,
    setup: 'Hold a strong glute bridge with feet under knees.',
    action:
        'Float one foot without letting the pelvis tip, replace, then switch.',
    breathing: 'Exhale on each foot lift.',
    cues: ['Belt line level', 'Small march', 'Glutes stay active'],
    avoid: 'Do not let the hips drop or roll toward the lifted side.',
  ),
  'Bird dog': ExerciseGuide(
    motion: ExerciseMotion.birdDog,
    setup:
        'Start on all fours with hands under shoulders and knees under hips.',
    action:
        'Reach opposite arm and leg long, pause, then return and alternate.',
    breathing: 'Exhale as you reach · inhale to reset.',
    cues: ['Square hips', 'Reach, do not lift', 'Back stays quiet'],
    avoid: 'Do not arch the lower back or rotate the pelvis.',
  ),
  '90/90 hip switch': ExerciseGuide(
    motion: ExerciseMotion.hipSwitch,
    setup: 'Sit tall with feet wider than hips and both knees bent.',
    action:
        'Rotate both knees together from one side to the other under control.',
    breathing: 'Exhale through the middle of each switch.',
    cues: ['Feet stay planted', 'Move from hips', 'Use hands if needed'],
    avoid: 'Do not force either knee to the floor.',
  ),
  'Child’s pose breathing': ExerciseGuide(
    motion: ExerciseMotion.childPose,
    setup:
        'Kneel comfortably, bring hips toward heels and reach hands forward.',
    action: 'Stay relaxed and expand the back and side ribs with every breath.',
    breathing: 'Inhale for four · exhale slowly for six.',
    cues: ['Forehead supported', 'Jaw relaxed', 'Wide back breath'],
    avoid: 'Use extra knee padding and stop if the position pinches the hips.',
  ),
  'World’s greatest stretch': ExerciseGuide(
    motion: ExerciseMotion.worldStretch,
    setup:
        'Take a long lunge and place the opposite hand inside the front foot.',
    action:
        'Rotate the free arm and chest upward, pause, then return with control.',
    breathing: 'Exhale into the rotation · inhale back down.',
    cues: ['Back leg long', 'Front foot grounded', 'Turn through upper back'],
    avoid: 'Do not force the front knee inward or crank the lower back.',
  ),
  'Standing cooldown flow': ExerciseGuide(
    motion: ExerciseMotion.standingFlow,
    setup: 'Stand softly with feet under hips and shoulders relaxed.',
    action:
        'Reach overhead, fold with bent knees, then roll up slowly to stand.',
    breathing: 'Inhale tall · exhale fold · inhale as you rise.',
    cues: ['Move slowly', 'Keep knees soft', 'Finish relaxed'],
    avoid: 'Do not lock the knees or rush through dizziness.',
  ),
  'Incline push-up': ExerciseGuide(
    motion: ExerciseMotion.inclinePushUp,
    setup:
        'Place hands on a firm raised surface and walk feet back into a plank.',
    action: 'Bring the chest toward the edge, then press the surface away.',
    breathing: 'Inhale down · exhale up.',
    cues: ['Surface cannot move', 'Body stays straight', 'Elbows about 45°'],
    avoid: 'Do not use a chair or table that can slide or tip.',
  ),
};
