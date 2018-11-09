modalIndicator = {}
modalIndicator.show = function(text)
  if modalIndicator._text then modalIndicator._text:hide(); end
  local rect = hs.geometry.rect(0,25,200,200)
  modalIndicator._text = hs.drawing.text(rect, text)
  modalIndicator._text:show();
end

modalIndicator.hide = function(text)
  modalIndicator._text:hide();
end
