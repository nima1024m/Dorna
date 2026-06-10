package com.dorna.app.keyboard

import android.content.Context
import android.inputmethodservice.InputMethodService
import android.inputmethodservice.Keyboard
import android.inputmethodservice.KeyboardView
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.text.TextUtils
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager

import com.dorna.app.R

class DornaKeyboardService : InputMethodService(), KeyboardView.OnKeyboardActionListener {

    private lateinit var keyboardView: KeyboardView
    private lateinit var keyboard: Keyboard
    private lateinit var numberKeyboard: Keyboard
    private lateinit var symbolKeyboard: Keyboard
    

    
    private var caps = false
    private var currentMode = KEYBOARD_LETTERS
    private var vibrator: Vibrator? = null

    companion object {
        private const val KEYBOARD_LETTERS = 0
        private const val KEYBOARD_NUMBERS = 1
        private const val KEYBOARD_SYMBOLS = 2

        // Vibration constants
        private const val VIBRATION_DURATION = 20L
        private const val VIBRATION_AMPLITUDE = 50
    }

    override fun onCreate() {
        super.onCreate()
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }
    
    override fun onCreateInputView(): View {
        keyboardView = layoutInflater.inflate(R.layout.keyboard_view, null) as KeyboardView
        keyboard = Keyboard(this, R.xml.keyboard_layout)
        numberKeyboard = Keyboard(this, R.xml.number_keyboard_layout)
        symbolKeyboard = Keyboard(this, R.xml.symbol_keyboard_layout)

        keyboardView.keyboard = keyboard
        keyboardView.setOnKeyboardActionListener(this)
        keyboardView.isPreviewEnabled = true

        return keyboardView
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        // Reset state
        switchToLetterKeyboard()
    }

    private fun switchToLetterKeyboard() {
        keyboard = Keyboard(this, R.xml.keyboard_layout)
        keyboardView.keyboard = keyboard
        currentMode = KEYBOARD_LETTERS
    }

    private fun switchToNumberKeyboard() {
        numberKeyboard = Keyboard(this, R.xml.number_keyboard_layout)
        keyboardView.keyboard = numberKeyboard
        currentMode = KEYBOARD_NUMBERS
    }

    private fun switchToSymbolKeyboard() {
        symbolKeyboard = Keyboard(this, R.xml.symbol_keyboard_layout)
        keyboardView.keyboard = symbolKeyboard
        currentMode = KEYBOARD_SYMBOLS
    }

    override fun onPress(primaryCode: Int) {
        // Play haptic feedback
        playHapticFeedback()
    }

    override fun onRelease(primaryCode: Int) {
        // Not used
    }

    override fun onKey(primaryCode: Int, keyCodes: IntArray?) {
        val ic = currentInputConnection
        when (primaryCode) {
            Keyboard.KEYCODE_DELETE -> {
                val selectedText = ic?.getSelectedText(0)
                if (TextUtils.isEmpty(selectedText)) {
                    // No selection, delete previous character
                    ic?.deleteSurroundingText(1, 0)
                } else {
                    // Delete the selection
                    ic?.commitText("", 1)
                }
            }

            Keyboard.KEYCODE_SHIFT -> {
                caps = !caps
                keyboard.isShifted = caps
                keyboardView.invalidateAllKeys()
            }

            Keyboard.KEYCODE_DONE -> {
                ic?.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
                ic?.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
            }

            -2 -> {
                // Switch to number keyboard
                if (currentMode == KEYBOARD_LETTERS) {
                    switchToNumberKeyboard()
                } else {
                    switchToLetterKeyboard()
                }
            }

            -10001 -> {
                // Emoji keyboard - not implemented
                // You would integrate with an emoji picker
            }

            -10002 -> {
                // Language switcher - open input method picker
                val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                imm.showInputMethodPicker()
            }

            32 -> {
                // Space key
                ic?.commitText(" ", 1)
            }

            46 -> {
                // Period key
                ic?.commitText(".", 1)
            }

            else -> {
                var code = primaryCode.toChar()
                if (caps && currentMode == KEYBOARD_LETTERS) {
                    code = code.uppercaseChar()
                }
                ic?.commitText(code.toString(), 1)
            }
        }
    }

    private fun playHapticFeedback() {
        vibrator?.let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                it.vibrate(VibrationEffect.createOneShot(VIBRATION_DURATION, VIBRATION_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                it.vibrate(VIBRATION_DURATION)
            }
        }
    }



    override fun onText(text: CharSequence?) {
        val ic = currentInputConnection ?: return
        ic.commitText(text, 1)
    }

    override fun swipeLeft() {
        // Not implemented
    }

    override fun swipeRight() {
        // Not implemented
    }

    override fun swipeDown() {
        // Close the keyboard
        requestHideSelf(0)
    }

    override fun swipeUp() {
        // Not implemented
    }
}