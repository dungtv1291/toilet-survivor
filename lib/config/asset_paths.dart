class AssetPaths {
  static const String playerSheet = 'player/player_idle_walk_sheet.png';
  static const List<String> playerSprites = [playerSheet];

  static const String poopBasicSheet = 'enemies/poop_basic_sheet.png';
  static const String poopSnakeSheet = 'enemies/poop_snake_sheet.png';
  static const String poopSnakeFolder = 'enemies/poop_snake/';
  static const String poopBossSheet = 'enemies/poop_boss_sheet.png';
  static const List<String> poopSnakeFrames = [
    'enemies/poop_snake/idle_back.png',
    'enemies/poop_snake/idle_front.png',
    'enemies/poop_snake/idle_left.png',
    'enemies/poop_snake/idle_right.png',
    'enemies/poop_snake/move_back_1.png',
    'enemies/poop_snake/move_back_2.png',
    'enemies/poop_snake/move_back_3.png',
    'enemies/poop_snake/move_front_1.png',
    'enemies/poop_snake/move_front_2.png',
    'enemies/poop_snake/move_front_3.png',
    'enemies/poop_snake/move_left_1.png',
    'enemies/poop_snake/move_left_2.png',
    'enemies/poop_snake/move_left_3.png',
    'enemies/poop_snake/move_right_1.png',
    'enemies/poop_snake/move_right_2.png',
    'enemies/poop_snake/move_right_3.png',
  ];
  static const List<String> enemySprites = [
    poopBasicSheet,
    poopSnakeSheet,
    poopBossSheet,
    ...poopSnakeFrames,
  ];

  static const String bullet = 'effects/effects/bullets/bullet_pistol.png';
  static const List<String> bulletSprites = [bullet];

  static const String muzzleFlash =
      'effects/effects/muzzle/bullet_muzzle_1.png';
  static const String muzzleFlash2 =
      'effects/effects/muzzle/bullet_muzzle_2.png';
  static const String muzzleFlash3 =
      'effects/effects/muzzle/bullet_muzzle_3.png';
  static const List<String> muzzleSprites = [
    muzzleFlash,
    muzzleFlash2,
    muzzleFlash3,
  ];

  static const String hitSpark = 'effects/effects/hit/hit_spark_1.png';
  static const String hitSpark2 = 'effects/effects/hit/hit_spark_2.png';
  static const String hitSpark3 = 'effects/effects/hit/hit_spark_3.png';
  static const List<String> hitSprites = [hitSpark, hitSpark2, hitSpark3];

  static const String poopSplat = 'effects/effects/splat/poop_splat_1.png';
  static const String poopSplat2 = 'effects/effects/splat/poop_splat_2.png';
  static const String poopSplat3 = 'effects/effects/splat/poop_splat_3.png';
  static const List<String> splatSprites = [poopSplat, poopSplat2, poopSplat3];

  static const String fartBurst = 'effects/effects/fart/fart_burst.png';
  static const String fartCloudMedium =
      'effects/effects/fart/fart_cloud_medium.png';
  static const String fartPuffSmall =
      'effects/effects/fart/fart_puff_small.png';
  static const String fartStream = 'effects/effects/fart/fart_stream.png';
  static const List<String> fartSprites = [
    fartBurst,
    fartCloudMedium,
    fartPuffSmall,
    fartStream,
  ];

  static const String stinkCloudSkull =
      'effects/effects/stink/stink_cloud_skull.png';
  static const String stinkCloudSmall =
      'effects/effects/stink/stink_cloud_small.png';
  static const List<String> stinkSprites = [stinkCloudSkull, stinkCloudSmall];

  static const String barrelRed = 'props/barrel_red.png';
  static const String brokenCar = 'props/broken_car.png';
  static const String metalBarricade = 'props/metal_barricade.png';
  static const String woodenCrate = 'props/wooden_crate.png';
  static const String toilet = 'props/toilet.png';
  static const String portableToilet = 'props/portable_toilet.png';
  static const String trashBin = 'props/trash_bin.png';
  static const String wetFloorSign = 'props/wet_floor_sign.png';
  static const String rockPile = 'props/rock_pile.png';
  static const String toiletPaperStack = 'props/toilet_paper_stack.png';
  static const String plungerGround = 'props/plunger_ground.png';

  static const List<String> propSprites = [
    barrelRed,
    brokenCar,
    metalBarricade,
    woodenCrate,
    toilet,
    portableToilet,
    trashBin,
    wetFloorSign,
    rockPile,
    toiletPaperStack,
    plungerGround,
  ];

  static const List<String> blockingPropSprites = [
    barrelRed,
    brokenCar,
    metalBarricade,
    woodenCrate,
    toilet,
    portableToilet,
    trashBin,
    wetFloorSign,
    rockPile,
  ];

  static const List<String> decorationPropSprites = [
    toiletPaperStack,
    plungerGround,
  ];

  static const String sludgePuddle = 'decals/sludge_puddle.png';
  static const List<String> decalSprites = [sludgePuddle];

  static const String hudCorner = 'ui/corners/corner_1.png';
  static const String hudSlimeDrip = 'ui/drips/slime_drip_1.png';

  static const String floorDirt = 'tiles/floor_dirt.png';
  static const String floorSewage = 'tiles/floor_sewage.png';
  static const String floorToiletDirty = 'tiles/floor_toilet_dirty.png';
  static const List<String> tileSprites = [
    floorDirt,
    floorSewage,
    floorToiletDirty,
  ];

  static const List<String> allImages = [
    ...playerSprites,
    ...enemySprites,
    ...propSprites,
    ...decalSprites,
    ...bulletSprites,
    ...muzzleSprites,
    ...hitSprites,
    ...fartSprites,
    ...splatSprites,
    ...stinkSprites,
    ...tileSprites,
    hudCorner,
    hudSlimeDrip,
  ];

  static String poopSnakeFrame(String name) {
    return '$poopSnakeFolder$name.png';
  }
}
