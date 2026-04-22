"""Tests for ui/text_utils.py"""
import pytest
import pygame

from ui.text_utils import wrap_text

pygame.init()
_FONT = pygame.font.SysFont("Arial", 12)


def test_short_text_fits_on_one_line():
    lines = wrap_text("Hello", _FONT, 500)
    assert lines == ["Hello"]


def test_long_text_splits_into_multiple_lines():
    text = "This is a very long sentence that should definitely wrap onto more than one line when the width is narrow"
    lines = wrap_text(text, _FONT, 200)
    assert len(lines) > 1
    # All words from original text must be present in output
    original_words = set(text.split())
    output_words = set(" ".join(lines).split())
    assert original_words == output_words


def test_empty_string_returns_empty_list():
    assert wrap_text("", _FONT, 300) == []


def test_single_word_wider_than_max_still_returned():
    lines = wrap_text("Superlongwordthatdoesnotfit", _FONT, 1)
    assert lines == ["Superlongwordthatdoesnotfit"]


def test_exact_fit_does_not_split():
    # A single word that fits exactly — should not be split
    word = "Test"
    width = _FONT.size(word)[0]
    lines = wrap_text(word, _FONT, width)
    assert lines == [word]
