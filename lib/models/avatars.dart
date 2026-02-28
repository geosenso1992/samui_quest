enum PlayerAvatar {
  monkey,
  frog,
  bird,
  elephant,
  turtle,
}

extension PlayerAvatarExtension on PlayerAvatar {
  String get assetPath {
    switch (this) {
      case PlayerAvatar.monkey:
        return "assets/monkey_player.png";
      case PlayerAvatar.frog:
        return "assets/frog_player.png";
      case PlayerAvatar.bird:
        return "assets/bird_player.png";
      case PlayerAvatar.elephant:
        return "assets/elephant_player.png";
      case PlayerAvatar.turtle:
        return "assets/turtle_player.png";
    }
  }

  String get displayName {
    switch (this) {
      case PlayerAvatar.monkey:
        return "Monkey Explorer";
      case PlayerAvatar.frog:
        return "Jungle Jumper";
      case PlayerAvatar.bird:
        return "Sky Scout";
      case PlayerAvatar.elephant:
        return "Mighty Tracker";
      case PlayerAvatar.turtle:
        return "Island Navigator";
    }
  }
}