/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import 'package:hm_animations/src/ui/animations/buffering/configuration/buffering_animation_configuration.dart';
import 'package:hm_animations/src/ui/animations/shared/legend/legend_drawable.dart';
import 'package:hm_animations/src/ui/animations/shared/legend/legend_item.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/grid_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout_mode.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/separator/vertical_separator_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plot.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/animated/animated_plottable_series.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable_series.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/line/line_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/point/point_painter.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/point/point_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/axis_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/coordinate_system_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/plot_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/tick_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/button/button_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/combo_box_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event_types.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/item/combo_box_item.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/listener/combo_box_model_change_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/simple_combo_box_model.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/slider/slider_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/text/input_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_service.dart';
import 'package:tuple/tuple.dart';

/// The root drawable of the buffering animation.
class BufferingAnimationDrawable extends Drawable {
  /// Base key of saved configurations in local storage.
  static const String _local_storage_key =
      "buffering-animation.configuration.v1";

  /// Allowed runes as seed (only numeric).
  static const List<int> _numericalRunes = [
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57
  ];

  /// Max seed for the random number generator.
  static final int _MAX_SEED = 9999999;

  /// Maximum transmission unit in bytes.
  static final int _MTU = 1500;

  /// Factor to slow the animation down.
  /// For example 1000: The animation is 1000 times slower.
  static final int _DEFAULT_SLOWDOWN_FACTOR = 1000;

  /// Random number generator used to generate seeds for another random number generator.
  static Random _rng = Random();

  /// Storage service used to store data locally.
  final StorageService _storageService;

  /// Service used to show dialogs.
  final DialogService _dialogService;

  /// Service used to fetch translations.
  final I18nService _i18nService;

  /// Slider used to specify the playback buffer size.
  _SliderContainer _playoutBufferSizeSlider;

  /// Slider used to specify the mean network rate.
  _SliderContainer _meanNetworkRateSlider;

  /// Slider used to specify the variance of the network rate.
  _SliderContainer _networkRateVarianceSlider;

  /// Slider used to specify the bit rate to stream with.
  _SliderContainer _bitRateSlider;

  /// Plot to display the result with.
  Plot _plot;

  /// Layout containing all controls of the animation.
  GridLayout _controlsLayout;

  /// Button used to pause the animation.
  ButtonDrawable _pauseButton;

  /// Button used to reset the animation.
  ButtonDrawable _resetButton;

  /// Button used to reseed the animations rng.
  ButtonDrawable _reseedButton;

  /// Input field to input a custom seed for the random number generator.
  InputDrawable _seedInput;

  /// Current seed for the random number generator.
  int _currentSeed;

  /// Animated plottable series showing the constant bit rate.
  AnimatedPlottableSeries _constantBitRatePlottable;

  /// Animated plottable series showing the network delayed series.
  AnimatedPlottableSeries _networkDelayedPlottable;

  /// Animated plottable series showing the playout at client series.
  AnimatedPlottableSeries _clientPlayOutPlottable;

  /// List of interruptions happened during client play out.
  List<Point<double>> _playOutInterruptions = List<Point<double>>();

  /// Operation running async to add the interrupt marker in the plot by the right time.
  Completer<void> _interruptOperation;

  /// Layout on the bottom.
  HorizontalLayout _bottomLayout;

  /// Container for the speed slider.
  _SliderContainer _speedSlider;

  /// Label of the interruption counter.
  TextDrawable _interruptionCounterLabel;

  /// Combo box input for previously saved settings.
  ComboBoxDrawable _savedSettingsComboBox;

  /// Change listener of the saved settings combo box model.
  ComboBoxModelChangeListener _savedSettingsComboBoxModelChangeListener;

  /// The current configuration of the animation.
  BufferingAnimationConfiguration _currentConfiguration;

  /// Button used to save the current configuration of the animation.
  ButtonDrawable _saveButton;

  /// Button used to restore the configuration for the animation.
  ButtonDrawable _restoreButton;

  /// Button used to remove a selected configuration.
  ButtonDrawable _removeConfigButton;

  /// Drawable showing the animations legend.
  LegendDrawable _legend;

  Message _interruptionsMsg;
  Message _bitRateMsg;
  Message _playoutBufferSizeMsg;
  Message _meanNetworkRateMsg;
  Message _networkRateVarianceMsg;
  Message _constantBitRateTransmissionMsg;
  Message _networkDelayedReceivingAtClientMsg;
  Message _constantBitRatePlayOutAtClientMsg;
  Message _cumulativeDataMsg;
  Message _timeInSMsg;
  Message _speedScaleMsg;
  Message _reseedMsg;
  Message _runMsg;
  Message _pauseMsg;
  Message _resetMsg;
  Message _newConfigurationMsg;
  Message _newConfigurationPromptMsg;
  Message _saveMsg;
  Message _loadMsg;
  Message _removeMsg;
  Message _packetsMsg;

  /// Listener getting notifications once the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Create the buffering animation drawable.
  BufferingAnimationDrawable(
    this._i18nService,
    this._storageService,
    this._dialogService,
  ) {
    _init();
  }

  /// Set the current animation configuration.
  void _setConfiguration({
    int seed,
    int bitRate,
    int bufferSize,
    int meanNetworkRate,
    int networkRateVariance,
  }) {
    if (bitRate == null) {
      bitRate = _bitRateSlider.slider.value.toInt() * 1000;
    } else {
      _bitRateSlider.slider
          .setValue(bitRate / 1000, informChangeListener: false);
    }

    if (bufferSize == null) {
      bufferSize = _playoutBufferSizeSlider.slider.value.toInt();
    } else {
      _playoutBufferSizeSlider.slider
          .setValue(bufferSize.toDouble(), informChangeListener: false);
    }

    if (meanNetworkRate == null) {
      meanNetworkRate =
          _meanNetworkRateSlider.slider.value.toInt() * 1000 * 1000;
    } else {
      _meanNetworkRateSlider.slider
          .setValue(meanNetworkRate / 1000000, informChangeListener: false);
    }

    if (networkRateVariance == null) {
      networkRateVariance =
          _networkRateVarianceSlider.slider.value.toInt() * 1000 * 1000;
    } else {
      _networkRateVarianceSlider.slider
          .setValue(networkRateVariance / 1000000, informChangeListener: false);
    }

    if (seed == null) {
      seed = _currentSeed;
    } else {
      _setSeed(seed);
    }

    _currentConfiguration = BufferingAnimationConfiguration(
      seed: seed,
      bitRate: bitRate,
      bufferSize: bufferSize,
      meanNetworkRate: meanNetworkRate,
      networkRateVariance: networkRateVariance,
    );

    _recalculateGraph(
      bitRate: _currentConfiguration.bitRate,
      playOutBufferSize: _currentConfiguration.bufferSize,
      meanNetworkRate: _currentConfiguration.meanNetworkRate ~/ 8,
      networkRateVariance: _currentConfiguration.networkRateVariance ~/ 8,
    );
  }

  /// Initialize needed translations for the animation.
  void _initTranslations() {
    _interruptionsMsg = _i18nService.get("buffering.interruptions");
    _bitRateMsg = _i18nService.get("buffering.bit-rate");
    _playoutBufferSizeMsg = _i18nService.get("buffering.playout-buffer-size");
    _meanNetworkRateMsg = _i18nService.get("buffering.mean-network-rate");
    _networkRateVarianceMsg =
        _i18nService.get("buffering.network-rate-variance");
    _constantBitRateTransmissionMsg =
        _i18nService.get("buffering.constant-bit-rate-transmission");
    _networkDelayedReceivingAtClientMsg =
        _i18nService.get("buffering.network-delayed-receiving-at-client");
    _constantBitRatePlayOutAtClientMsg =
        _i18nService.get("buffering.constant-bit-rate-play-out-at-client");
    _cumulativeDataMsg = _i18nService.get("buffering.cumulative-data");
    _timeInSMsg = _i18nService.get("buffering.time-in-s");
    _speedScaleMsg = _i18nService.get("buffering.speed-scale");
    _reseedMsg = _i18nService.get("buffering.reseed");
    _runMsg = _i18nService.get("buffering.run");
    _pauseMsg = _i18nService.get("buffering.pause");
    _resetMsg = _i18nService.get("buffering.reset");
    _newConfigurationMsg = _i18nService.get("buffering.new-configuration");
    _newConfigurationPromptMsg =
        _i18nService.get("buffering.new-configuration.prompt");
    _saveMsg = _i18nService.get("buffering.save");
    _loadMsg = _i18nService.get("buffering.load");
    _removeMsg = _i18nService.get("buffering.remove");
    _packetsMsg = _i18nService.get("buffering.packets");

    _languageLoadedListener = (_) => _updateTranslations();
    _i18nService.addLanguageLoadedListener(_languageLoadedListener);
  }

  /// Update the translations used in the animation.
  void _updateTranslations() {
    _playoutBufferSizeSlider.label.text = _playoutBufferSizeMsg.toString();
    _bitRateSlider.label.text = _bitRateMsg.toString();
    _meanNetworkRateSlider.label.text = _bitRateMsg.toString();
    _networkRateVarianceSlider.label.text = _networkRateVarianceMsg.toString();
    _interruptionCounterLabel.text =
        _interruptionsMsg.toString() + ": ${_playOutInterruptions.length}";
    _speedSlider.label.text = _speedScaleMsg.toString();
    _reseedButton.text = _reseedMsg.toString();
    _resetButton.text = _resetMsg.toString();
    _pauseButton.text = _constantBitRatePlottable.paused
        ? _pauseMsg.toString()
        : _runMsg.toString();
    _savedSettingsComboBox.model.items.first.label =
        _newConfigurationMsg.toString();
    if (_savedSettingsComboBox.model.selected ==
        _savedSettingsComboBox.model.items.first) {
      _savedSettingsComboBox.model
          .select(_savedSettingsComboBox.model.selected);
    }
    _saveButton.text = _saveMsg.toString();
    _restoreButton.text = _loadMsg.toString();
    _removeConfigButton.text = _removeMsg.toString();
    _legend.updateItems([
      LegendItem(
          color: Colors.PINK_RED_2,
          text: _constantBitRateTransmissionMsg.toString()),
      LegendItem(
          color: Colors.BLUE_GRAY,
          text: _networkDelayedReceivingAtClientMsg.toString()),
      LegendItem(
          color: Colors.GREY_GREEN,
          text: _constantBitRatePlayOutAtClientMsg.toString()),
    ]);
    _plot.invalidateCoordinateSystem();
    double oldBufferSize = _playoutBufferSizeSlider.slider.value;
    _playoutBufferSizeSlider.slider
        .setValue(oldBufferSize + 1, informChangeListener: false);
    _playoutBufferSizeSlider.slider
        .setValue(oldBufferSize, informChangeListener: false);
  }

  /// Initialize the drawable.
  void _init() {
    _initTranslations();
    _reseed(); // Initially seeding the random number generator.

    SliderValueChangeCallback changeCallback = (_) {
      _setConfiguration();
    };

    _playoutBufferSizeSlider = _createSlider(
      label: _playoutBufferSizeMsg.toString(),
      changeCallback: changeCallback,
      min: 1,
      max: 10,
      value: 2,
      step: 1,
      valueFormatter: (value) => "${value.toInt()} ${_packetsMsg.toString()}",
    );

    _bitRateSlider = _createSlider(
      label: _bitRateMsg.toString(),
      changeCallback: changeCallback,
      min: 100,
      max: 20000,
      value: 5000,
      step: 100,
      valueFormatter: (value) => "${value.toInt()} kBit/s",
    );

    _meanNetworkRateSlider = _createSlider(
      label: _meanNetworkRateMsg.toString(),
      changeCallback: (value) {
        _networkRateVarianceSlider.slider.max = value;
        changeCallback(value);
      },
      min: 1,
      max: 100,
      value: 16,
      step: 1,
      valueFormatter: (value) => "${value.toInt()} Mbit/s",
    );

    _networkRateVarianceSlider = _createSlider(
      label: _networkRateVarianceMsg.toString(),
      changeCallback: changeCallback,
      min: 0,
      max: _meanNetworkRateSlider.slider.value,
      value: 5,
      step: 1,
      valueFormatter: (value) => "${value.toInt()} Mbit/s",
    );

    _plot = Plot(
      parent: this,
      yMin: 0,
      yMax: 10,
      xMin: 0,
      xMax: 0.05,
      style: PlotStyle(
        coordinateSystem: CoordinateSystemStyle(
          xAxis: AxisStyle(
            labelGenerator: () => _timeInSMsg.toString(),
            color: Colors.LIGHTGREY,
            lineWidth: 2,
            ticks: TickStyle(generator: TickStyle.fixedCountTicksGenerator(5)),
          ),
          yAxis: AxisStyle(
            labelGenerator: () => _cumulativeDataMsg.toString(),
            color: Colors.LIGHTGREY,
            lineWidth: 2,
            ticks: TickStyle(
                generator: TickStyle.fixedCountTicksGenerator(2),
                labelRenderer: (value) => value.toInt().toString()),
          ),
        ),
      ),
    );

    _legend = LegendDrawable(
      items: [
        LegendItem(
            color: Colors.PINK_RED_2,
            text: _constantBitRateTransmissionMsg.toString()),
        LegendItem(
            color: Colors.BLUE_GRAY,
            text: _networkDelayedReceivingAtClientMsg.toString()),
        LegendItem(
            color: Colors.GREY_GREEN,
            text: _constantBitRatePlayOutAtClientMsg.toString()),
      ],
    );

    _interruptionCounterLabel = TextDrawable(
      alignment: TextAlignment.LEFT,
      color: Colors.PINK_RED_2,
      text: _interruptionsMsg.toString() + ": 0",
      textSize: CanvasContextUtil.DEFAULT_FONT_SIZE_PX * 1.3,
    );

    _controlsLayout = GridLayout(
      parent: this,
      cells: [
        CellSpec(row: 0, column: 0, drawable: _bitRateSlider.drawable),
        CellSpec(row: 0, column: 1, drawable: _meanNetworkRateSlider.drawable),
        CellSpec(
            row: 1, column: 0, drawable: _playoutBufferSizeSlider.drawable),
        CellSpec(
            row: 1, column: 1, drawable: _networkRateVarianceSlider.drawable),
        CellSpec(row: 0, column: 2, drawable: _legend),
        CellSpec(row: 1, column: 2, drawable: _interruptionCounterLabel),
      ],
    );

    _speedSlider = _createSlider(
      label: _speedScaleMsg.toString(),
      min: 100,
      max: 2000,
      value: _DEFAULT_SLOWDOWN_FACTOR.toDouble(),
      step: 100,
      valueFormatter: (i) => "1:$i",
      changeCallback: changeCallback,
    );
    _bottomLayout = HorizontalLayout(
      parent: this,
      alignment: VerticalAlignment.CENTER,
      layoutMode: LayoutMode.FIT,
      children: [
        _speedSlider.drawable,
        VerticalLayout(
          alignment: HorizontalAlignment.CENTER,
          layoutMode: LayoutMode.FIT,
          children: [
            _seedInput = InputDrawable(
              maxLength: _MAX_SEED.toString().length,
              width: 80,
              value: _currentSeed.toString(),
              filter: (toInsert) =>
                  toInsert.runes.firstWhere((c) => !_numericalRunes.contains(c),
                      orElse: () => -1) ==
                  -1,
              onChange: (value) {
                int v = int.tryParse(value);
                if (v != null) {
                  _currentSeed = v;
                  _unpause();
                  changeCallback(null);
                }
              },
            ),
            _reseedButton = ButtonDrawable(
              text: _reseedMsg.toString(),
              onClick: () {
                _unpause();
                _reseed();
                changeCallback(null);
              },
            ),
          ],
        ),
        VerticalSeparatorDrawable(
          xPadding: 15,
        ),
        VerticalLayout(
          alignment: HorizontalAlignment.CENTER,
          children: [
            _pauseButton = ButtonDrawable(
              text: _pauseMsg.toString(),
              onClick: () {
                _switchPause();
              },
            ),
            _resetButton = ButtonDrawable(
              text: _resetMsg.toString(),
              onClick: () {
                _unpause();
                changeCallback(null);
              },
            ),
          ],
        ),
        VerticalSeparatorDrawable(
          xPadding: 15,
        ),
        _savedSettingsComboBox = ComboBoxDrawable(
          model: SimpleComboBoxModel<BufferingAnimationConfiguration>(
            items: [
              ComboBoxItem<BufferingAnimationConfiguration>(
                  label: _newConfigurationMsg.toString(), obj: null),
            ]..addAll(_loadConfigurations()),
          ),
        ),
        _saveButton = ButtonDrawable(
          text: _saveMsg.toString(),
          onClick: () => _saveConfiguration(),
        ),
        _restoreButton = ButtonDrawable(
          text: _loadMsg.toString(),
          onClick: () => _restoreConfiguration(),
          disabled: true,
        ),
        _removeConfigButton = ButtonDrawable(
          text: _removeMsg.toString(),
          onClick: () => _removeConfiguration(),
          disabled: true,
        ),
      ],
    );

    _savedSettingsComboBox.model.select(
        _savedSettingsComboBox.model.get(0)); // Select first item by default
    _savedSettingsComboBoxModelChangeListener =
        (event) => _onSavedSettingsComboBoxModelChanged(event);
    _savedSettingsComboBox.model
        .addChangeListener(_savedSettingsComboBoxModelChangeListener);

    changeCallback(null);
  }

  @override
  void cleanup() {
    if (_savedSettingsComboBoxModelChangeListener != null) {
      _savedSettingsComboBox.model
          .removeChangeListener(_savedSettingsComboBoxModelChangeListener);
    }

    _i18nService.removeLanguageLoadedListener(_languageLoadedListener);

    super.cleanup();
  }

  /// What to do when the saved settings combo box model changes.
  void _onSavedSettingsComboBoxModelChanged(ComboBoxModelEvent event) {
    if (event.type == ComboBoxModelEventType.SELECTED) {
      ComboBoxItem<BufferingAnimationConfiguration> selected =
          _savedSettingsComboBox.model.selected;

      if (selected.obj == null) {
        // Is new configuration selected -> Only enable the save button
        _saveButton.disabled = false;
        _restoreButton.disabled = true;
        _removeConfigButton.disabled = true;
      } else {
        // Is saved configuration selected -> Enable both the save and load button
        _saveButton.disabled = false;
        _restoreButton.disabled = false;
        _removeConfigButton.disabled = false;
      }
    }
  }

  /// Load all available configurations from local storage.
  List<ComboBoxItem<BufferingAnimationConfiguration>> _loadConfigurations() {
    List<String> keys = _storageService.getKeys();
    List<ComboBoxItem<BufferingAnimationConfiguration>> result = [];
    for (final key in keys) {
      if (key.startsWith(_local_storage_key)) {
        result.add(ComboBoxItem<BufferingAnimationConfiguration>(
          label: keyToItemLabel(key),
          obj: BufferingAnimationConfiguration.fromJson(
              json.decode(_storageService.get(key))),
        ));
      }
    }

    return result;
  }

  /// Save the current configuration in the currently selected combo box item.
  Future<void> _saveConfiguration() async {
    // Check whether the currently selected configuration is pointing to "new configuration" or a already existing one.
    ComboBoxItem<BufferingAnimationConfiguration> selectedConfiguration =
        _savedSettingsComboBox.model.selected;
    bool isNew = selectedConfiguration.obj == null;

    ComboBoxItem<BufferingAnimationConfiguration> item;
    if (isNew) {
      String name;
      do {
        name = await _askForConfigurationName();
      } while (name != null && name.trim().isEmpty);

      if (name == null) {
        // Cancel the save process
        return;
      }

      item = ComboBoxItem<BufferingAnimationConfiguration>(
        label: name,
        obj: _currentConfiguration,
      );
    } else {
      item = ComboBoxItem<BufferingAnimationConfiguration>(
        label: selectedConfiguration.label,
        obj: _currentConfiguration,
      );

      _savedSettingsComboBox.model.remove(selectedConfiguration);
    }

    _savedSettingsComboBox.model.add(item);
    _savedSettingsComboBox.model.select(item);

    _storageService.set(getKeyForItem(item), json.encode(item.obj.toJson()));
  }

  /// Ask for a configuration name.
  Future<String> _askForConfigurationName() async {
    return await _dialogService
        .prompt(_newConfigurationPromptMsg.toString())
        .result();
  }

  String itemLabelToKey(String label) =>
      label.replaceAll(new RegExp(r"\s+\b|\b\s"), "_");

  String keyToItemLabel(String key) {
    String labelKey = key.substring(_local_storage_key.length + 1);
    return labelKey.replaceAll("_", " ");
  }

  String getKeyForItem(ComboBoxItem item) =>
      "${_local_storage_key}.${itemLabelToKey(item.label)}";

  /// Restore the configuration in the currently selected combo box item.
  void _restoreConfiguration() {
    BufferingAnimationConfiguration config =
        _savedSettingsComboBox.model.selected.obj;

    _setConfiguration(
      seed: config.seed,
      bitRate: config.bitRate,
      bufferSize: config.bufferSize,
      meanNetworkRate: config.meanNetworkRate,
      networkRateVariance: config.networkRateVariance,
    );
  }

  /// Remove the currently selected configuration.
  void _removeConfiguration() {
    final item = _savedSettingsComboBox.model.selected;
    _savedSettingsComboBox.model.select(_savedSettingsComboBox.model.get(0));
    _savedSettingsComboBox.model.remove(item);

    _storageService.remove(getKeyForItem(item));
  }

  /// Unpause the animation.
  void _unpause() {
    if (_constantBitRatePlottable != null && _constantBitRatePlottable.paused) {
      _switchPause();
    }
  }

  /// Switch the pause state.
  void _switchPause() {
    bool isPaused = _constantBitRatePlottable.paused;

    if (isPaused) {
      _constantBitRatePlottable.unpause();
      _networkDelayedPlottable.unpause();
      _clientPlayOutPlottable.unpause();

      _pauseButton.text = _pauseMsg.toString();
    } else {
      _constantBitRatePlottable.pause();
      _networkDelayedPlottable.pause();
      _clientPlayOutPlottable.pause();

      _pauseButton.text = _runMsg.toString();
    }
  }

  /// Get the currently set slow down factor.
  int get _slowDownFactor => _speedSlider != null
      ? _speedSlider.slider.value.toInt()
      : _DEFAULT_SLOWDOWN_FACTOR;

  /// Create a slider input control.
  _SliderContainer _createSlider({
    String label,
    SliderValueChangeCallback changeCallback,
    double min,
    double max,
    double value,
    double step,
    ValueFormatter valueFormatter,
  }) {
    var slider = SliderDrawable(
      value: value,
      min: min,
      max: max,
      step: step,
      changeCallback: changeCallback,
      style: SliderStyle(
        valueFormatter: valueFormatter,
      ),
    );

    var labelDrawable = TextDrawable(
      text: label,
    );

    var drawable = VerticalLayout(
      alignment: HorizontalAlignment.CENTER,
      children: [labelDrawable, slider],
    );

    return _SliderContainer(slider, drawable, labelDrawable);
  }

  /// Recalculate the result graph.
  void _recalculateGraph({
    int playOutBufferSize,
    int meanNetworkRate,
    int networkRateVariance,
    int bitRate,
  }) {
    final double secondsPerMTU = _MTU / (bitRate / 8);

    if (_interruptOperation != null && !_interruptOperation.isCompleted) {
      _interruptOperation.complete();
    }

    // Reset plot
    _plot.removeAll();
    _plot.maxY = 10;
    _plot.maxX = 0.05;

    // Create constant bit rate series
    _constantBitRatePlottable = AnimatedPlottableSeries(
      seriesGenerator: _constantBitRateSeriesGenerator(secondsPerMTU).iterator,
      style: PlottableStyle(line: LineStyle(color: Colors.PINK_RED_2)),
    );
    _plot.add(_constantBitRatePlottable);

    // Create network delayed series
    _networkDelayedPlottable = AnimatedPlottableSeries(
      seriesGenerator: _networkDelayedSeriesGenerator(
              secondsPerMTU, meanNetworkRate, networkRateVariance)
          .iterator,
      style: PlottableStyle(line: LineStyle(color: Colors.BLUE_GRAY)),
    );
    _plot.add(_networkDelayedPlottable);

    // Create client playout series
    _clientPlayOutPlottable = AnimatedPlottableSeries(
      seriesGenerator:
          _clientPlayOutSeriesGenerator(secondsPerMTU, playOutBufferSize)
              .iterator,
      style: PlottableStyle(line: LineStyle(color: Colors.GREY_GREEN)),
    );
    _plot.add(_clientPlayOutPlottable);

    _playOutInterruptions.clear();
    if (_interruptionCounterLabel != null) {
      _interruptionCounterLabel.text = _interruptionsMsg.toString() + ": 0";
    }
    _plot.add(PlottableSeries(
      points: _playOutInterruptions,
      style: PlottableStyle(
        line: null,
        points: PointStyle(
          painter: PointPainterFactory.getInstance("o"),
          color: Colors.RED,
        ),
      ),
    ));

    invalidate();
  }

  /// Generator of the constant bit rate series.
  Iterable<Tuple2<Iterable<Point<double>>, Duration>>
      _constantBitRateSeriesGenerator(double secondsPerMTU) sync* {
    final double secondsPerMTUInSimulation = secondsPerMTU * _slowDownFactor;
    final int millisecondsInSimulation =
        (secondsPerMTUInSimulation * 1000).toInt();

    yield Tuple2([Point<double>(0, 0), Point<double>(0, 0)],
        Duration(seconds: 0)); // Initial point

    double timeInSeconds = 0;
    double mtuCount = 0;
    while (true) {
      timeInSeconds += secondsPerMTU;

      _ensureVisibleInPlot(0, mtuCount + 1);
      yield Tuple2(
        [
          Point<double>(timeInSeconds, mtuCount),
          Point<double>(timeInSeconds, ++mtuCount),
        ],
        Duration(milliseconds: millisecondsInSimulation),
      );
    }
  }

  /// Generator of the network delayed series.
  Iterable<Tuple2<Iterable<Point<double>>, Duration>>
      _networkDelayedSeriesGenerator(double secondsPerMTU, int meanNetworkRate,
          int networkRateVariance) sync* {
    final random = Random(_currentSeed);

    yield Tuple2([Point<double>(0, 0), Point<double>(0, 0)],
        Duration(seconds: 0)); // Initial point

    double mtuCount = 0;
    bool isFirst = true;
    num lastReceived = secondsPerMTU;
    while (true) {
      // Check if packet already sent, otherwise it cannot be received and we need to append additional time
      bool readyToReceive =
          _constantBitRatePlottable.generatedCount - 1 > mtuCount + 1;

      double networkRate = meanNetworkRate.toDouble();
      if (networkRateVariance > 0) {
        networkRate += (random.nextDouble() - 0.5 * 2) * networkRateVariance;
      }

      double timeForPacket = _MTU / networkRate;
      if (!readyToReceive) {
        double timeToWait =
            _constantBitRatePlottable.next.first.x - lastReceived;
        timeForPacket += timeToWait;
      }

      int ms = (timeForPacket * _slowDownFactor * 1000).toInt();
      if (isFirst) {
        isFirst = false;
        ms += (lastReceived * _slowDownFactor * 1000).toInt();
      }

      lastReceived += timeForPacket;

      yield Tuple2(
        [
          Point<double>(lastReceived, mtuCount),
          Point<double>(lastReceived, ++mtuCount),
        ],
        Duration(milliseconds: ms),
      );
    }
  }

  /// Generator for the client playout series.
  Iterable<Tuple2<Iterable<Point<double>>, Duration>>
      _clientPlayOutSeriesGenerator(
          double secondsPerMTU, int bufferSize) sync* {
    final int neededBufferedPackets = bufferSize;

    yield Tuple2([Point<double>(0, 0), Point<double>(0, 0)],
        Duration(seconds: 0)); // Initial point

    bool playingOut =
        false; // Whether the streamed data is currently played out at client or buffering
    int playedOut = 0; // Number of packets played out.
    double lastReceived = 0;
    double lastPlayedOut = 0;
    while (true) {
      double nextPacketReceivedTime = _networkDelayedPlottable.next.first.x;
      int receivedPackets = _networkDelayedPlottable.generatedCount - 2;
      int buffered = receivedPackets - playedOut;

      final bool waitForPacket = !playingOut ||
          buffered <= 0 &&
              nextPacketReceivedTime > lastPlayedOut + secondsPerMTU;
      if (waitForPacket) {
        _ensureVisibleInPlot(nextPacketReceivedTime, 0);

        if (playingOut) {
          // No more packets to play out. Play out is interrupted!
          double interruptionTime = lastPlayedOut + secondsPerMTU;
          playingOut = false;
          _onPlayOutInterrupted(interruptionTime, lastPlayedOut, playedOut);
          yield Tuple2(
              [
                Point<double>(nextPacketReceivedTime, playedOut.toDouble()),
                Point<double>(nextPacketReceivedTime, playedOut.toDouble())
              ],
              Duration(
                  milliseconds: ((nextPacketReceivedTime - lastPlayedOut) *
                          _slowDownFactor *
                          1000)
                      .toInt()));
          lastReceived = nextPacketReceivedTime;
        } else {
          if (buffered + 1 >= neededBufferedPackets) {
            playingOut = true;
            yield Tuple2(
                [
                  Point<double>(nextPacketReceivedTime, playedOut.toDouble()),
                  Point<double>(
                      nextPacketReceivedTime, (++playedOut).toDouble())
                ],
                Duration(
                    milliseconds: ((nextPacketReceivedTime - lastReceived) *
                            _slowDownFactor *
                            1000)
                        .toInt()));
            lastReceived = nextPacketReceivedTime;
            lastPlayedOut = nextPacketReceivedTime;
          } else {
            yield Tuple2(
                [
                  Point<double>(nextPacketReceivedTime, playedOut.toDouble()),
                  Point<double>(nextPacketReceivedTime, playedOut.toDouble())
                ],
                Duration(
                    milliseconds: ((nextPacketReceivedTime - lastReceived) *
                            _slowDownFactor *
                            1000)
                        .toInt()));
            lastReceived = nextPacketReceivedTime;
          }
        }
      } else {
        // Playing out buffered packet.
        _ensureVisibleInPlot(lastPlayedOut + secondsPerMTU, 0);
        yield Tuple2(
            [
              Point<double>(
                  lastPlayedOut + secondsPerMTU, playedOut.toDouble()),
              Point<double>(
                  lastPlayedOut + secondsPerMTU, (++playedOut).toDouble())
            ],
            Duration(
                milliseconds:
                    (secondsPerMTU * _slowDownFactor * 1000).toInt()));
        lastPlayedOut += secondsPerMTU;
      }
    }
  }

  /// Ensure that the passed x and y coordinates are visible in the plot.
  void _ensureVisibleInPlot(double x, double y) {
    if (x > _plot.maxX) {
      _plot.maxX = x;
    }

    if (y > _plot.maxY) {
      _plot.maxY = y;
    }
  }

  /// Called when the play out at client is interrupted.
  void _onPlayOutInterrupted(
      double interruptionTime, double lastPlayedOutTime, int playedOut) {
    final completer = Completer<void>();
    _interruptOperation = completer;
    Future.delayed(Duration(
            milliseconds: ((interruptionTime - lastPlayedOutTime) *
                    _slowDownFactor *
                    1000)
                .toInt()))
        .then(
      (_) {
        if (!completer.isCompleted) {
          _playOutInterruptions
              .add(Point<double>(interruptionTime, playedOut.toDouble()));
          _plot.invalidate();

          _interruptionCounterLabel.text = _interruptionsMsg.toString() +
              ": ${_playOutInterruptions.length}";
        }
      },
    );
  }

  /// Reseed the random number generator used by the animation.
  void _reseed() {
    _setSeed(_rng.nextInt(_MAX_SEED));
  }

  /// Set a seed to the animation.
  void _setSeed(int seed) {
    _currentSeed = seed;

    if (_seedInput != null) {
      _seedInput.value = seed.toString();
    }
  }

  @override
  void draw() {
    _controlsLayout.render(ctx, lastPassTimestamp,
        x: max(0, (size.width - _controlsLayout.size.width) / 2));

    double graphSpacing = 10 * window.devicePixelRatio;

    _drawGraph(
      x: 0,
      y: _controlsLayout.size.height + graphSpacing,
      width: size.width,
      height: size.height -
          _controlsLayout.size.height -
          _bottomLayout.size.height -
          graphSpacing * 2,
    );

    _bottomLayout.render(ctx, lastPassTimestamp,
        x: max(0, (size.width - _bottomLayout.size.width) / 2),
        y: size.height - _bottomLayout.size.height);
  }

  /// Get the maximum value of the passed values.
  double maxValue(List<double> values) =>
      values.reduce((currentMax, value) => max(currentMax, value));

  /// Draw the result graph.
  void _drawGraph({
    double x = 0,
    double y = 0,
    double width,
    double height,
  }) {
    _plot.setSize(
      width: width,
      height: height,
    );
    _plot.render(
      ctx,
      lastPassTimestamp,
      x: x,
      y: y,
    );
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    if (_constantBitRatePlottable != null) if (_constantBitRatePlottable
        .requestUpdate(timestamp)) _plot.invalidate();
    if (_networkDelayedPlottable != null) if (_networkDelayedPlottable
        .requestUpdate(timestamp)) _plot.invalidate();
    if (_clientPlayOutPlottable != null) if (_clientPlayOutPlottable
        .requestUpdate(timestamp)) _plot.invalidate();
  }
}

class _SliderContainer {
  final SliderDrawable slider;
  final Drawable drawable;
  final TextDrawable label;

  _SliderContainer(this.slider, this.drawable, this.label);
}
