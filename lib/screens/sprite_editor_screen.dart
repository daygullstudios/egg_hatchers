import 'package:flutter/material.dart';

import '../data/sprite_reference_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/custom_sprite_data.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/sprite_rating_service.dart';
import '../services/sprite_reference_overlay_service.dart';
import '../theme/game_theme.dart';
import '../navigation/app_page_route.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/sprite_rating_logic.dart';
import '../utils/ui_sound.dart';
import '../widgets/custom_sprite_preview.dart';
import '../widgets/game_background.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/pixel_sprite.dart';

enum ReferenceOverlayStrength {
  low,
  medium,
  high;

  double get opacity => switch (this) {
    ReferenceOverlayStrength.low => 0.20,
    ReferenceOverlayStrength.medium => 0.30,
    ReferenceOverlayStrength.high => 0.45,
  };

  String get label => switch (this) {
    ReferenceOverlayStrength.low => 'Low',
    ReferenceOverlayStrength.medium => 'Medium',
    ReferenceOverlayStrength.high => 'High',
  };
}

/// Simple 16×16 pixel editor for one animal sprite.
class SpriteEditorScreen extends StatefulWidget {
  const SpriteEditorScreen({
    super.key,
    required this.animal,
    required this.theme,
    required this.customSprites,
    required this.game,
    required this.spriteRating,
    required this.referenceOverlay,
  });

  final Animal animal;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final GameService game;
  final SpriteRatingService spriteRating;
  final SpriteReferenceOverlayService referenceOverlay;

  @override
  State<SpriteEditorScreen> createState() => _SpriteEditorScreenState();
}

class _SpriteEditorScreenState extends State<SpriteEditorScreen> {
  static const _maxHistory = 30;

  late CustomSpriteData _data;
  late int _canvasSize;
  int? _selectedColor = SpritePalette.colors.first;
  SpriteEditorTool _tool = SpriteEditorTool.pencil;
  int _brushSize = 1;
  bool _showGrid = true;
  bool _showReferenceOverlay = false;
  ReferenceOverlayStrength _overlayStrength = ReferenceOverlayStrength.medium;
  int? _ratedScore;
  int? _ratedReward;
  final List<CustomSpriteData> _undoStack = [];
  final List<CustomSpriteData> _redoStack = [];

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _data =
        widget.customSprites.getSprite(widget.animal.id) ??
        CustomSpriteData.empty();
    _canvasSize = _data.size;
  }

  int get _maxCanvasSize => widget.game.maxCustomSpriteGridSize;

  CustomSpriteData _emptyCanvas() =>
      CustomSpriteData.empty(gridSize: _canvasSize);

  void _clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void _pushUndo() {
    _undoStack.add(_data.copyWith());
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _setData(CustomSpriteData next, {bool clearRating = true}) {
    setState(() {
      _data = next;
      if (clearRating) {
        _ratedScore = null;
        _ratedReward = null;
      }
    });
  }

  void _onStrokeStart() => _pushUndo();

  void _onEditorChanged(CustomSpriteData next) => _setData(next);

  void _undo() {
    if (!_canUndo) return;
    _redoStack.add(_data.copyWith());
    _setData(_undoStack.removeLast());
  }

  void _redo() {
    if (!_canRedo) return;
    _undoStack.add(_data.copyWith());
    _setData(_redoStack.removeLast());
  }

  void _clear() {
    _pushUndo();
    _setData(_emptyCanvas());
  }

  Future<void> _confirmClear() async {
    if (!_data.hasVisiblePixels) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear sprite?'),
        content: const Text('This will erase your current drawing.'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _clear();
    }
  }

  void _onColorPicked(int? color) {
    if (color == null) {
      showGameSnackBar(
        context,
        message: 'No color here — try another pixel.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() {
      _selectedColor = color;
      _tool = SpriteEditorTool.pencil;
      _ratedScore = null;
      _ratedReward = null;
    });
  }

  void _clearRating() {
    setState(() {
      _ratedScore = null;
      _ratedReward = null;
    });
  }

  Future<void> _unlockReferenceOverlay() async {
    if (widget.referenceOverlay.isUnlocked(widget.animal.id)) return;

    final displayedReward = _ratedReward;
    if (!widget.game.canAffordReferenceOverlay(
      widget.animal.id,
      displayedReward: displayedReward,
    )) {
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: 'Not enough coins to unlock overlay.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final unlocked = await widget.game.unlockReferenceOverlay(
      widget.animal.id,
      widget.referenceOverlay,
      displayedReward: displayedReward,
    );
    if (!mounted) return;

    if (unlocked) {
      UiSound.purchase(context);
      showGameSnackBar(
        context,
        message: 'Reference Overlay unlocked!',
        backgroundColor: widget.theme.primaryColor,
      );
    } else {
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: 'Not enough coins to unlock overlay.',
        backgroundColor: Colors.orange.shade700,
      );
    }
  }

  CustomSpriteData? get _savedSprite =>
      widget.customSprites.getSprite(widget.animal.id);

  bool get _hasUnsavedChanges {
    final saved = _savedSprite;
    if (saved == null) return _data.hasVisiblePixels;
    return !SpriteRatingLogic.spritesEqual(saved, _data);
  }

  void _rateSprite() {
    final reference = SpriteReferenceData.referenceFor(widget.animal.id);
    if (reference == null) return;

    if (!_data.hasVisiblePixels) {
      setState(() {
        _ratedScore = 0;
        _ratedReward = 0;
      });
      return;
    }

    final score = SpriteRatingLogic.displayScore(_data, reference);
    final reward = SpriteRatingLogic.calculateReward(
      animalId: widget.animal.id,
      score: score,
      currentCoins: widget.game.coins,
    );

    widget.game.recordSpriteRated(
      animalId: widget.animal.id,
      score: score,
      spriteHash: SpriteRatingLogic.computeSpriteHash(_data),
    );

    setState(() {
      _ratedScore = score;
      _ratedReward = reward;
    });
  }

  bool get _ratingAlreadyCountedForCurrentDrawing {
    if (!_data.hasVisiblePixels) return false;
    return widget.game.isSpriteRatingCountedForQuest(
      widget.animal.id,
      SpriteRatingLogic.computeSpriteHash(_data),
    );
  }

  Future<void> _claimReward() async {
    final reference = SpriteReferenceData.referenceFor(widget.animal.id);
    if (reference == null) return;

    final saved = _savedSprite;
    if (saved == null || !saved.hasVisiblePixels) {
      showGameSnackBar(
        context,
        message: 'Save your sprite before claiming a reward.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    if (_hasUnsavedChanges) {
      showGameSnackBar(
        context,
        message: 'Save your sprite before claiming a reward.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final hash = SpriteRatingLogic.computeSpriteHash(saved);
    if (widget.spriteRating.isClaimed(widget.animal.id, hash)) {
      showGameSnackBar(
        context,
        message: 'Reward already claimed for this sprite.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final score = SpriteRatingLogic.displayScore(saved, reference);
    if (score < 1) {
      showGameSnackBar(
        context,
        message: 'Score too low to claim a reward.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final reward = SpriteRatingLogic.calculateReward(
      animalId: widget.animal.id,
      score: score,
      currentCoins: widget.game.coins,
    );
    if (reward <= 0) return;

    final recorded = await widget.spriteRating.recordClaim(
      animalId: widget.animal.id,
      spriteHash: hash,
      score: score,
      rewardCoins: reward,
    );
    if (!recorded || !mounted) return;

    final granted = widget.game.grantSpriteRatingReward(reward);
    if (granted == null || !mounted) return;

    widget.game.recordSpriteRatingRewardClaimed();

    setState(() {
      _ratedScore = score;
      _ratedReward = reward;
    });

    showGameSnackBar(
      context,
      message: 'Sprite rated! +${formatCoins(granted)} coins',
      backgroundColor: widget.theme.secondaryColor,
    );
    UiSound.rewardTriumph(context);
  }

  Future<void> _save() async {
    await widget.customSprites.saveSprite(widget.animal.id, _data);
    if (!mounted) return;

    final reference = SpriteReferenceData.referenceFor(widget.animal.id);
    if (reference != null && _data.hasVisiblePixels) {
      final score = SpriteRatingLogic.displayScore(_data, reference);
      final reward = SpriteRatingLogic.calculateReward(
        animalId: widget.animal.id,
        score: score,
        currentCoins: widget.game.coins,
      );
      setState(() {
        _ratedScore = score;
        _ratedReward = reward;
      });
    } else {
      _clearRating();
    }

    showGameSnackBar(
      context,
      message: '${widget.animal.name} sprite saved!',
      backgroundColor: widget.theme.primaryColor,
    );
    UiSound.confirm(context);
  }

  Future<void> _reset() async {
    await widget.customSprites.resetSprite(widget.animal.id);
    if (!mounted) return;
    _clearHistory();
    setState(() {
      _data = _emptyCanvas();
      _ratedScore = null;
      _ratedReward = null;
    });
    showGameSnackBar(
      context,
      message: '${widget.animal.name} reset to original sprite.',
      backgroundColor: widget.theme.secondaryColor,
    );
  }

  void _selectColor(int? color) {
    setState(() {
      _selectedColor = color;
      if (color == SpritePalette.transparent) {
        _tool = SpriteEditorTool.eraser;
      } else if (_tool == SpriteEditorTool.eraser) {
        _tool = SpriteEditorTool.pencil;
      }
      _ratedScore = null;
      _ratedReward = null;
    });
  }

  void _selectTool(SpriteEditorTool tool) {
    setState(() {
      _tool = tool;
      if (tool == SpriteEditorTool.eraser) {
        _selectedColor = SpritePalette.transparent;
      } else if (tool == SpriteEditorTool.pencil &&
          _selectedColor == SpritePalette.transparent) {
        _selectedColor = SpritePalette.colors.first;
      }
    });
  }

  bool get _showsBrushSize =>
      _tool == SpriteEditorTool.pencil || _tool == SpriteEditorTool.eraser;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return ReturnToCustomSpritesPopScope(
      theme: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PhoneWidthAppBar.widget(
          titleWidget: Text(
            '✏️ ${widget.animal.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: theme.appBarColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: ReturnToCustomSpritesBackButton(
            theme: theme,
            color: Colors.white,
          ),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([
            widget.game,
            widget.spriteRating,
            widget.referenceOverlay,
          ]),
          builder: (context, _) {
            return _buildBody(theme);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BackgroundTheme theme) {
    final hasReference = SpriteReferenceData.hasReference(widget.animal.id);
    final ratingReference = SpriteReferenceData.referenceFor(widget.animal.id);
    final saved = _savedSprite;
    final savedHash = saved != null
        ? SpriteRatingLogic.computeSpriteHash(saved)
        : null;
    final alreadyClaimed =
        savedHash != null &&
        widget.spriteRating.isClaimed(widget.animal.id, savedHash);
    final canClaim =
        hasReference &&
        _ratedScore != null &&
        _ratedScore! >= 1 &&
        !_hasUnsavedChanges &&
        saved != null &&
        saved.hasVisiblePixels &&
        !alreadyClaimed;
    final overlayUnlocked = widget.referenceOverlay.isUnlocked(
      widget.animal.id,
    );
    final overlayCost = widget.game.referenceOverlayCostForAnimal(
      widget.animal.id,
      displayedReward: _ratedReward,
    );

    return GameBackground(
      theme: theme,
      child: PhoneWidthLayout(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: GameTheme.cardDecoration(theme),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Tap or drag to draw. Use pencil, fill, eraser, '
                      'or eyedropper. Undo and redo your changes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ToolsPanel(
                      theme: theme,
                      tool: _tool,
                      brushSize: _brushSize,
                      showGrid: _showGrid,
                      showBrushSize: _showsBrushSize,
                      canUndo: _canUndo,
                      canRedo: _canRedo,
                      onToolSelected: _selectTool,
                      onBrushSizeSelected: (size) =>
                          setState(() => _brushSize = size),
                      onShowGridChanged: (value) =>
                          setState(() => _showGrid = value),
                      onUndo: _undo,
                      onRedo: _redo,
                    ),
                    if (_maxCanvasSize > CustomSpriteData.defaultGridSize) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Canvas:',
                            style: TextStyle(
                              color: theme.cardTextSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _canvasSize,
                            items:
                                [
                                      CustomSpriteData.defaultGridSize,
                                      if (_maxCanvasSize >=
                                          CustomSpriteData.expandedGridSize)
                                        CustomSpriteData.expandedGridSize,
                                    ]
                                    .map(
                                      (size) => DropdownMenuItem(
                                        value: size,
                                        child: Text('$size x $size'),
                                      ),
                                    )
                                    .toList(),
                            onChanged: _data.hasVisiblePixels
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _canvasSize = value;
                                      _data = _emptyCanvas();
                                      _clearHistory();
                                    });
                                  },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    PixelSpriteEditor(
                      data: _data,
                      selectedColor: _selectedColor,
                      tool: _tool,
                      brushSize: _brushSize,
                      showGrid: _showGrid,
                      onStrokeStart: _onStrokeStart,
                      onChanged: _onEditorChanged,
                      onColorPicked: _onColorPicked,
                      canvasSize: 240,
                      themeColor: theme.primaryColor,
                      referenceOverlay: ratingReference,
                      showReferenceOverlay:
                          hasReference &&
                          overlayUnlocked &&
                          _showReferenceOverlay,
                      overlayOpacity: _overlayStrength.opacity,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ReferencePreviewsPanel(
                theme: theme,
                animal: widget.animal,
                customData: _data,
                ratingReference: ratingReference,
                hasReference: hasReference,
              ),
              const SizedBox(height: 16),
              _ReferenceToolsPanel(
                theme: theme,
                hasReference: hasReference,
                overlayUnlocked: overlayUnlocked,
                overlayCost: overlayCost,
                showReferenceOverlay: _showReferenceOverlay,
                overlayStrength: _overlayStrength,
                onUnlockOverlay: hasReference && !overlayUnlocked
                    ? _unlockReferenceOverlay
                    : null,
                onShowOverlayChanged: hasReference && overlayUnlocked
                    ? (value) => setState(() => _showReferenceOverlay = value)
                    : null,
                onOverlayStrengthChanged: hasReference && overlayUnlocked
                    ? (value) => setState(() => _overlayStrength = value)
                    : null,
              ),
              const SizedBox(height: 16),
              _RatingCard(
                theme: theme,
                hasReference: hasReference,
                customData: _data,
                ratingReference: ratingReference,
                ratedScore: _ratedScore,
                ratedReward: _ratedReward,
                ratingAlreadyCounted: _ratingAlreadyCountedForCurrentDrawing,
                alreadyClaimed: alreadyClaimed,
                hasUnsavedChanges: _hasUnsavedChanges,
                canClaim: canClaim,
                onRate: _rateSprite,
                onClaim: _claimReward,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: GameTheme.cardDecoration(theme),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Palette',
                      style: GameTheme.sectionTitle(theme, size: 15),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PaletteSwatch(
                          label: 'Eraser',
                          color: Colors.transparent,
                          isSelected: _tool == SpriteEditorTool.eraser,
                          onTap: () => _selectTool(SpriteEditorTool.eraser),
                          showEraserIcon: true,
                          theme: theme,
                        ),
                      ],
                    ),
                    for (final group in SpritePalette.groups) ...[
                      const SizedBox(height: 12),
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: theme.cardTextSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in group.entries)
                            _PaletteSwatch(
                              label: entry.label,
                              color: Color(entry.color),
                              isSelected:
                                  _tool != SpriteEditorTool.eraser &&
                                  _selectedColor == entry.color,
                              onTap: () {
                                _selectTool(SpriteEditorTool.pencil);
                                _selectColor(entry.color);
                              },
                              theme: theme,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _data.hasVisiblePixels ? _confirmClear : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: theme.cardTextPrimaryColor,
                        side: BorderSide(color: theme.cardBorderColor),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: theme.cardTextPrimaryColor,
                        side: BorderSide(color: theme.cardBorderColor),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _save,
                style: GameTheme.filledButton(
                  theme,
                  color: theme.primaryColor,
                  height: 52,
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Save Sprite',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferencePreviewsPanel extends StatelessWidget {
  const _ReferencePreviewsPanel({
    required this.theme,
    required this.animal,
    required this.customData,
    required this.ratingReference,
    required this.hasReference,
  });

  final BackgroundTheme theme;
  final Animal animal;
  final CustomSpriteData customData;
  final CustomSpriteData? ratingReference;
  final bool hasReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameTheme.cardDecoration(theme),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Previews', style: GameTheme.sectionTitle(theme, size: 15)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final useRow = constraints.maxWidth >= 400;
              final previewSize = useRow ? 88.0 : 96.0;

              final tiles = <Widget>[
                _PreviewTile(
                  theme: theme,
                  label: 'Built-in Style',
                  child: CustomSpritePreview(
                    animalId: animal.id,
                    spritePath: animal.spritePath,
                    fallbackEmoji: animal.emoji,
                    size: previewSize,
                    emojiFontSize: previewSize * 0.65,
                    semanticLabel: '${animal.name} original sprite',
                  ),
                ),
                _PreviewTile(
                  theme: theme,
                  label: 'Your Sprite',
                  child: customData.hasVisiblePixels
                      ? PixelSprite(data: customData, size: previewSize)
                      : _EmptyPreviewFrame(
                          theme: theme,
                          size: previewSize,
                          label: 'Empty',
                        ),
                ),
                if (hasReference && ratingReference != null)
                  _PreviewTile(
                    theme: theme,
                    label: 'Rating Reference',
                    child: PixelSprite(
                      data: ratingReference!,
                      size: previewSize,
                      showGrid: true,
                      gridColor: theme.cardBorderColor.withValues(alpha: 0.35),
                    ),
                  ),
              ];

              if (useRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                );
              }

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: tiles,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyPreviewFrame extends StatelessWidget {
  const _EmptyPreviewFrame({
    required this.theme,
    required this.size,
    required this.label,
  });

  final BackgroundTheme theme;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.cardBorderColor.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: theme.cardTextSecondaryColor),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.theme,
    required this.label,
    required this.child,
  });

  final BackgroundTheme theme;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.cardTextSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.cardBorderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Center(child: child),
        ),
      ],
    );
  }
}

class _ReferenceToolsPanel extends StatelessWidget {
  const _ReferenceToolsPanel({
    required this.theme,
    required this.hasReference,
    required this.overlayUnlocked,
    required this.overlayCost,
    required this.showReferenceOverlay,
    required this.overlayStrength,
    required this.onUnlockOverlay,
    required this.onShowOverlayChanged,
    required this.onOverlayStrengthChanged,
  });

  final BackgroundTheme theme;
  final bool hasReference;
  final bool overlayUnlocked;
  final int overlayCost;
  final bool showReferenceOverlay;
  final ReferenceOverlayStrength overlayStrength;
  final VoidCallback? onUnlockOverlay;
  final ValueChanged<bool>? onShowOverlayChanged;
  final ValueChanged<ReferenceOverlayStrength>? onOverlayStrengthChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameTheme.cardDecoration(theme),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reference Tools',
            style: GameTheme.sectionTitle(theme, size: 15),
          ),
          const SizedBox(height: 10),
          if (!hasReference)
            Text(
              'Reference tools are available when a rating reference exists.',
              style: TextStyle(
                fontSize: 13,
                color: theme.cardTextSecondaryColor,
                height: 1.35,
              ),
            )
          else ...[
            if (!overlayUnlocked) ...[
              Text(
                'Overlay helps you trace the reference, so it costs coins.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.cardTextSecondaryColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cost is based on this animal\'s rating reward.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.cardTextSecondaryColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onUnlockOverlay,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.layers_rounded),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unlock Overlay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${formatCoins(overlayCost)} coins',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Show Reference Overlay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.cardTextPrimaryColor,
                    ),
                  ),
                  subtitle: Text(
                    'Faint rating reference behind your drawing canvas.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.cardTextSecondaryColor,
                    ),
                  ),
                  value: showReferenceOverlay,
                  activeThumbColor: theme.primaryColor,
                  onChanged: onShowOverlayChanged,
                ),
              ),
              if (showReferenceOverlay) ...[
                const SizedBox(height: 8),
                Text(
                  'Overlay Opacity',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final strength in ReferenceOverlayStrength.values)
                      _ToolChip(
                        theme: theme,
                        label: strength.label,
                        selected: overlayStrength == strength,
                        onTap: () => onOverlayStrengthChanged?.call(strength),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.theme,
    required this.hasReference,
    required this.customData,
    required this.ratingReference,
    required this.ratedScore,
    required this.ratedReward,
    required this.ratingAlreadyCounted,
    required this.alreadyClaimed,
    required this.hasUnsavedChanges,
    required this.canClaim,
    required this.onRate,
    required this.onClaim,
  });

  final BackgroundTheme theme;
  final bool hasReference;
  final CustomSpriteData customData;
  final CustomSpriteData? ratingReference;
  final int? ratedScore;
  final int? ratedReward;
  final bool ratingAlreadyCounted;
  final bool alreadyClaimed;
  final bool hasUnsavedChanges;
  final bool canClaim;
  final VoidCallback onRate;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameTheme.cardDecoration(theme),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rate Sprite (Beta)',
            style: GameTheme.sectionTitle(theme, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Draw a custom sprite and rate how closely it matches the animal. '
            'Clear shapes, legs, ears, tails, wings, and matching colors help '
            'your score.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: theme.cardTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasReference) ...[
            Text(
              'Rating is available for animals with built-in sprite references.',
              style: TextStyle(
                fontSize: 13,
                color: theme.cardTextSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: null,
              style: GameTheme.filledButton(
                theme,
                color: theme.disabledColor,
                height: 48,
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Rate Sprite (Beta)'),
            ),
          ] else ...[
            if (ratedScore != null) ...[
              Text(
                'Score: $ratedScore / 10',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.cardTextPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ratingReference == null
                    ? SpriteRatingLogic.ratingMessage(ratedScore!)
                    : SpriteRatingLogic.ratingFeedback(
                        customData,
                        ratingReference!,
                        ratedScore!,
                      ),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.cardTextSecondaryColor,
                ),
              ),
              if (ratedReward != null && ratedScore! >= 1) ...[
                const SizedBox(height: 6),
                Text(
                  'Reward: +${formatCoins(ratedReward!)} coins',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
            if (alreadyClaimed)
              Text(
                'Reward already claimed for this sprite.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor,
                ),
              )
            else if (hasUnsavedChanges &&
                ratedScore != null &&
                ratedScore! >= 1)
              Text(
                'Save your sprite before claiming a reward.',
                style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ratingAlreadyCounted ? null : onRate,
              style: GameTheme.filledButton(
                theme,
                color: ratingAlreadyCounted
                    ? theme.disabledColor
                    : theme.panelAccentColor,
                height: 48,
              ),
              icon: Icon(
                ratingAlreadyCounted
                    ? Icons.check_circle_rounded
                    : Icons.auto_awesome_rounded,
              ),
              label: Text(
                ratingAlreadyCounted ? 'Rated' : 'Rate Sprite (Beta)',
              ),
            ),
            if (ratingAlreadyCounted) ...[
              const SizedBox(height: 8),
              Text(
                'Edit your sprite to rate a new drawing.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.cardTextSecondaryColor,
                ),
              ),
            ],
            if (ratedScore != null && ratedScore! >= 1) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: canClaim ? onClaim : null,
                style: GameTheme.filledButton(
                  theme,
                  color: canClaim ? theme.secondaryColor : theme.disabledColor,
                  height: 48,
                ),
                icon: const Icon(Icons.redeem_rounded),
                label: const Text('Claim Reward'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({
    required this.theme,
    required this.tool,
    required this.brushSize,
    required this.showGrid,
    required this.showBrushSize,
    required this.canUndo,
    required this.canRedo,
    required this.onToolSelected,
    required this.onBrushSizeSelected,
    required this.onShowGridChanged,
    required this.onUndo,
    required this.onRedo,
  });

  final BackgroundTheme theme;
  final SpriteEditorTool tool;
  final int brushSize;
  final bool showGrid;
  final bool showBrushSize;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<SpriteEditorTool> onToolSelected;
  final ValueChanged<int> onBrushSizeSelected;
  final ValueChanged<bool> onShowGridChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tools', style: GameTheme.sectionTitle(theme, size: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ToolChip(
              theme: theme,
              label: 'Pencil',
              icon: Icons.edit_rounded,
              selected: tool == SpriteEditorTool.pencil,
              onTap: () => onToolSelected(SpriteEditorTool.pencil),
            ),
            _ToolChip(
              theme: theme,
              label: 'Fill',
              icon: Icons.format_color_fill_rounded,
              selected: tool == SpriteEditorTool.fill,
              onTap: () => onToolSelected(SpriteEditorTool.fill),
            ),
            _ToolChip(
              theme: theme,
              label: 'Eraser',
              icon: Icons.auto_fix_off_rounded,
              selected: tool == SpriteEditorTool.eraser,
              onTap: () => onToolSelected(SpriteEditorTool.eraser),
            ),
            _ToolChip(
              theme: theme,
              label: 'Pick',
              icon: Icons.colorize_rounded,
              selected: tool == SpriteEditorTool.eyedropper,
              onTap: () => onToolSelected(SpriteEditorTool.eyedropper),
            ),
          ],
        ),
        if (showBrushSize) ...[
          const SizedBox(height: 12),
          Text(
            'Brush: ${brushSize}x$brushSize',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.cardTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in [1, 2, 3])
                _ToolChip(
                  theme: theme,
                  label: '${size}x$size',
                  selected: brushSize == size,
                  onTap: () => onBrushSizeSelected(size),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Undo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: theme.cardTextPrimaryColor,
                  side: BorderSide(color: theme.cardBorderColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canRedo ? onRedo : null,
                icon: const Icon(Icons.redo_rounded, size: 18),
                label: const Text('Redo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: theme.cardTextPrimaryColor,
                  side: BorderSide(color: theme.cardBorderColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Show Grid',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.cardTextPrimaryColor,
              ),
            ),
            value: showGrid,
            activeThumbColor: theme.primaryColor,
            onChanged: onShowGridChanged,
          ),
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final BackgroundTheme theme;
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.primaryColor.withValues(alpha: 0.15)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? theme.primaryColor : theme.cardBorderColor,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? theme.primaryColor
                      : theme.cardTextSecondaryColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? theme.primaryColor
                      : theme.cardTextPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    this.showEraserIcon = false,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final BackgroundTheme theme;
  final bool showEraserIcon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: showEraserIcon ? Colors.white : color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? theme.primaryColor : theme.cardBorderColor,
              width: isSelected ? 3 : 1.5,
            ),
          ),
          child: showEraserIcon
              ? Icon(
                  Icons.auto_fix_off_rounded,
                  size: 20,
                  color: theme.cardTextSecondaryColor,
                )
              : null,
        ),
      ),
    );
  }
}
