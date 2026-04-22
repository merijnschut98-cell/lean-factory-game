"""Shared text utilities for pygame UI panels."""
from __future__ import annotations
from typing import List

import pygame


def wrap_text(text: str, font: pygame.font.Font, max_width: int) -> List[str]:
    """Word-wrap text into lines that fit within max_width pixels."""
    words = text.split()
    lines: List[str] = []
    line = ""
    for word in words:
        candidate = f"{line} {word}".strip()
        if font.size(candidate)[0] > max_width:
            if line:
                lines.append(line)
            line = word
        else:
            line = candidate
    if line:
        lines.append(line)
    return lines
