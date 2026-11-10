-- Terminal key migration. cmd+k retains the Rex session picker.
-- ~/.tmux.conf:6
rex.bind("ctrl+space>ctrl+space", "pane.send_key", { key = "ctrl+space" })
-- ~/.tmux.conf:26
rex.bind("ctrl+space>r", "client.config.reload")
-- ~/.tmux.conf:56
rex.bind("ctrl+space>shift+h", "pane.resize", { amount = 5, direction = "left" })
-- ~/.tmux.conf:57
rex.bind("ctrl+space>shift+j", "pane.resize", { amount = 5, direction = "down" })
-- ~/.tmux.conf:59
rex.bind("ctrl+space>shift+l", "pane.resize", { amount = 5, direction = "right" })
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+space>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
-- ~/.tmux.conf:56 (repeat mode)
rex.bind("repeat/shift+h", "pane.resize", { amount = 5, direction = "left" })
-- ~/.tmux.conf:57 (repeat mode)
rex.bind("repeat/shift+j", "pane.resize", { amount = 5, direction = "down" })
-- ~/.tmux.conf:58 (repeat mode)
rex.bind("repeat/shift+k", "pane.resize", { amount = 5, direction = "up" })
-- ~/.tmux.conf:59 (repeat mode)
rex.bind("repeat/shift+l", "pane.resize", { amount = 5, direction = "right" })
-- ~/.config/herdr/config.toml:7
rex.bind("ctrl+space>i", "pane.zoom")
-- ~/.config/herdr/config.toml:10
rex.bind("alt+h", "client.tab.previous")
-- ~/.config/herdr/config.toml:11
rex.bind("alt+l", "client.tab.next")
-- ~/.config/herdr/config.toml:14
rex.bind("ctrl+space>v", "pane.split", { direction = "right" })
-- ~/.config/herdr/config.toml:15
rex.bind("ctrl+space>s", "pane.split", { direction = "down" })
-- ~/.config/herdr/config.toml:16
rex.bind("ctrl+space>k", "pane.close")
-- ~/.config/herdr/config.toml:17
rex.bind("ctrl+space>shift+k", "client.tab.close")
-- ~/.config/alacritty/alacritty.yml:328
rex.bind("shift+pageup", "pane.send_key", { key = "shift+pageup" })
-- ~/.config/alacritty/alacritty.yml:329
rex.bind("ctrl+pageup", "pane.send_key", { key = "ctrl+pageup" })
-- ~/.config/alacritty/alacritty.yml:330
rex.bind("pageup", "pane.send_key", { key = "pageup" })
-- ~/.config/alacritty/alacritty.yml:331
rex.bind("shift+pagedown", "pane.send_key", { key = "shift+pagedown" })
-- ~/.config/alacritty/alacritty.yml:332
rex.bind("ctrl+pagedown", "pane.send_key", { key = "ctrl+pagedown" })
-- ~/.config/alacritty/alacritty.yml:333
rex.bind("pagedown", "pane.send_key", { key = "pagedown" })
-- ~/.config/alacritty/alacritty.yml:334
rex.bind("shift+tab", "pane.send_key", { key = "shift+tab" })
-- ~/.config/alacritty/alacritty.yml:335
rex.bind("backspace", "pane.send_key", { key = "backspace" })
-- ~/.config/alacritty/alacritty.yml:338
rex.bind("alt+backspace", "pane.send_key", { key = "alt+backspace" })
-- ~/.config/alacritty/alacritty.yml:339
rex.bind("insert", "pane.send_key", { key = "insert" })
-- ~/.config/alacritty/alacritty.yml:340
rex.bind("delete", "pane.send_key", { key = "delete" })
-- ~/.config/alacritty/alacritty.yml:341
rex.bind("shift+left", "pane.send_key", { key = "shift+left" })
-- ~/.config/alacritty/alacritty.yml:342
rex.bind("ctrl+left", "pane.send_key", { key = "ctrl+left" })
-- ~/.config/alacritty/alacritty.yml:343
rex.bind("alt+left", "pane.send_key", { key = "alt+left" })
-- ~/.config/alacritty/alacritty.yml:346
rex.bind("shift+right", "pane.send_key", { key = "shift+right" })
-- ~/.config/alacritty/alacritty.yml:347
rex.bind("ctrl+right", "pane.send_key", { key = "ctrl+right" })
-- ~/.config/alacritty/alacritty.yml:348
rex.bind("alt+right", "pane.send_key", { key = "alt+right" })
-- ~/.config/alacritty/alacritty.yml:351
rex.bind("shift+up", "pane.send_key", { key = "shift+up" })
-- ~/.config/alacritty/alacritty.yml:352
rex.bind("ctrl+up", "pane.send_key", { key = "ctrl+up" })
-- ~/.config/alacritty/alacritty.yml:353
rex.bind("alt+up", "pane.send_key", { key = "alt+up" })
-- ~/.config/alacritty/alacritty.yml:356
rex.bind("shift+down", "pane.send_key", { key = "shift+down" })
-- ~/.config/alacritty/alacritty.yml:357
rex.bind("ctrl+down", "pane.send_key", { key = "ctrl+down" })
-- ~/.config/alacritty/alacritty.yml:358
rex.bind("alt+down", "pane.send_key", { key = "alt+down" })
-- ~/.config/alacritty/alacritty.yml:361
rex.bind("f1", "pane.send_key", { key = "f1" })
-- ~/.config/alacritty/alacritty.yml:362
rex.bind("f2", "pane.send_key", { key = "f2" })
-- ~/.config/alacritty/alacritty.yml:363
rex.bind("f3", "pane.send_key", { key = "f3" })
-- ~/.config/alacritty/alacritty.yml:364
rex.bind("f4", "pane.send_key", { key = "f4" })
-- ~/.config/alacritty/alacritty.yml:365
rex.bind("f5", "pane.send_key", { key = "f5" })
-- ~/.config/alacritty/alacritty.yml:366
rex.bind("f6", "pane.send_key", { key = "f6" })
-- ~/.config/alacritty/alacritty.yml:367
rex.bind("f7", "pane.send_key", { key = "f7" })
-- ~/.config/alacritty/alacritty.yml:368
rex.bind("f8", "pane.send_key", { key = "f8" })
-- ~/.config/alacritty/alacritty.yml:369
rex.bind("f9", "pane.send_key", { key = "f9" })
-- ~/.config/alacritty/alacritty.yml:370
rex.bind("f10", "pane.send_key", { key = "f10" })
-- ~/.config/alacritty/alacritty.yml:371
rex.bind("f11", "pane.send_key", { key = "f11" })
-- ~/.config/alacritty/alacritty.yml:372
rex.bind("f12", "pane.send_key", { key = "f12" })
-- ~/.config/alacritty/alacritty.yml:373
rex.bind("shift+f1", "pane.send_key", { key = "shift+f1" })
-- ~/.config/alacritty/alacritty.yml:374
rex.bind("shift+f2", "pane.send_key", { key = "shift+f2" })
-- ~/.config/alacritty/alacritty.yml:375
rex.bind("shift+f3", "pane.send_key", { key = "shift+f3" })
-- ~/.config/alacritty/alacritty.yml:376
rex.bind("shift+f4", "pane.send_key", { key = "shift+f4" })
-- ~/.config/alacritty/alacritty.yml:377
rex.bind("shift+f5", "pane.send_key", { key = "shift+f5" })
-- ~/.config/alacritty/alacritty.yml:378
rex.bind("shift+f6", "pane.send_key", { key = "shift+f6" })
-- ~/.config/alacritty/alacritty.yml:379
rex.bind("shift+f7", "pane.send_key", { key = "shift+f7" })
-- ~/.config/alacritty/alacritty.yml:380
rex.bind("shift+f8", "pane.send_key", { key = "shift+f8" })
-- ~/.config/alacritty/alacritty.yml:381
rex.bind("shift+f9", "pane.send_key", { key = "shift+f9" })
-- ~/.config/alacritty/alacritty.yml:382
rex.bind("shift+f10", "pane.send_key", { key = "shift+f10" })
-- ~/.config/alacritty/alacritty.yml:383
rex.bind("shift+f11", "pane.send_key", { key = "shift+f11" })
-- ~/.config/alacritty/alacritty.yml:384
rex.bind("shift+f12", "pane.send_key", { key = "shift+f12" })
-- ~/.config/alacritty/alacritty.yml:385
rex.bind("ctrl+f1", "pane.send_key", { key = "ctrl+f1" })
-- ~/.config/alacritty/alacritty.yml:386
rex.bind("ctrl+f2", "pane.send_key", { key = "ctrl+f2" })
-- ~/.config/alacritty/alacritty.yml:387
rex.bind("ctrl+f3", "pane.send_key", { key = "ctrl+f3" })
-- ~/.config/alacritty/alacritty.yml:388
rex.bind("ctrl+f4", "pane.send_key", { key = "ctrl+f4" })
-- ~/.config/alacritty/alacritty.yml:389
rex.bind("ctrl+f5", "pane.send_key", { key = "ctrl+f5" })
-- ~/.config/alacritty/alacritty.yml:390
rex.bind("ctrl+f6", "pane.send_key", { key = "ctrl+f6" })
-- ~/.config/alacritty/alacritty.yml:391
rex.bind("ctrl+f7", "pane.send_key", { key = "ctrl+f7" })
-- ~/.config/alacritty/alacritty.yml:392
rex.bind("ctrl+f8", "pane.send_key", { key = "ctrl+f8" })
-- ~/.config/alacritty/alacritty.yml:393
rex.bind("ctrl+f9", "pane.send_key", { key = "ctrl+f9" })
-- ~/.config/alacritty/alacritty.yml:394
rex.bind("ctrl+f10", "pane.send_key", { key = "ctrl+f10" })
-- ~/.config/alacritty/alacritty.yml:395
rex.bind("ctrl+f11", "pane.send_key", { key = "ctrl+f11" })
-- ~/.config/alacritty/alacritty.yml:396
rex.bind("ctrl+f12", "pane.send_key", { key = "ctrl+f12" })
-- ~/.config/alacritty/alacritty.yml:397
rex.bind("alt+f1", "pane.send_key", { key = "ctrl+shift+f1" })
-- ~/.config/alacritty/alacritty.yml:398
rex.bind("alt+f2", "pane.send_key", { key = "ctrl+shift+f2" })
-- ~/.config/alacritty/alacritty.yml:399
rex.bind("alt+f3", "pane.send_key", { key = "ctrl+shift+f3" })
-- ~/.config/alacritty/alacritty.yml:400
rex.bind("alt+f4", "pane.send_key", { key = "ctrl+shift+f4" })
-- ~/.config/alacritty/alacritty.yml:401
rex.bind("alt+f5", "pane.send_key", { key = "ctrl+shift+f5" })
-- ~/.config/alacritty/alacritty.yml:402
rex.bind("alt+f6", "pane.send_key", { key = "ctrl+shift+f6" })
-- ~/.config/alacritty/alacritty.yml:403
rex.bind("alt+f7", "pane.send_key", { key = "ctrl+shift+f7" })
-- ~/.config/alacritty/alacritty.yml:404
rex.bind("alt+f8", "pane.send_key", { key = "ctrl+shift+f8" })
-- ~/.config/alacritty/alacritty.yml:405
rex.bind("alt+f9", "pane.send_key", { key = "ctrl+shift+f9" })
-- ~/.config/alacritty/alacritty.yml:406
rex.bind("alt+f10", "pane.send_key", { key = "ctrl+shift+f10" })
-- ~/.config/alacritty/alacritty.yml:407
rex.bind("alt+f11", "pane.send_key", { key = "ctrl+shift+f11" })
-- ~/.config/alacritty/alacritty.yml:408
rex.bind("alt+f12", "pane.send_key", { key = "ctrl+shift+f12" })
-- ~/.config/alacritty/alacritty.yml:409
rex.bind("alt+a", "pane.send_key", { key = "alt+a" })
-- ~/.config/alacritty/alacritty.yml:410
rex.bind("alt+b", "pane.send_key", { key = "alt+b" })
-- ~/.config/alacritty/alacritty.yml:411
rex.bind("alt+c", "pane.send_key", { key = "alt+c" })
-- ~/.config/alacritty/alacritty.yml:412
rex.bind("alt+d", "pane.send_key", { key = "alt+d" })
-- ~/.config/alacritty/alacritty.yml:413
rex.bind("alt+e", "pane.send_key", { key = "alt+e" })
-- ~/.config/alacritty/alacritty.yml:414
rex.bind("alt+f", "pane.send_key", { key = "alt+f" })
-- ~/.config/alacritty/alacritty.yml:415
rex.bind("alt+g", "pane.send_key", { key = "alt+g" })
-- ~/.config/alacritty/alacritty.yml:417
rex.bind("alt+i", "pane.send_key", { key = "alt+i" })
-- ~/.config/alacritty/alacritty.yml:418
rex.bind("alt+j", "pane.send_key", { key = "alt+j" })
-- ~/.config/alacritty/alacritty.yml:419
rex.bind("alt+k", "pane.send_key", { key = "alt+k" })
-- ~/.config/alacritty/alacritty.yml:421
rex.bind("alt+m", "pane.send_key", { key = "alt+m" })
-- ~/.config/alacritty/alacritty.yml:422
rex.bind("alt+n", "pane.send_key", { key = "alt+n" })
-- ~/.config/alacritty/alacritty.yml:423
rex.bind("alt+o", "pane.send_key", { key = "alt+o" })
-- ~/.config/alacritty/alacritty.yml:424
rex.bind("alt+p", "pane.send_key", { key = "alt+p" })
-- ~/.config/alacritty/alacritty.yml:425
rex.bind("alt+q", "pane.send_key", { key = "alt+q" })
-- ~/.config/alacritty/alacritty.yml:426
rex.bind("alt+r", "pane.send_key", { key = "alt+r" })
-- ~/.config/alacritty/alacritty.yml:427
rex.bind("alt+s", "pane.send_key", { key = "alt+s" })
-- ~/.config/alacritty/alacritty.yml:428
rex.bind("alt+t", "pane.send_key", { key = "alt+t" })
-- ~/.config/alacritty/alacritty.yml:429
rex.bind("alt+u", "pane.send_key", { key = "alt+u" })
-- ~/.config/alacritty/alacritty.yml:430
rex.bind("alt+v", "pane.send_key", { key = "alt+v" })
-- ~/.config/alacritty/alacritty.yml:431
rex.bind("alt+w", "pane.send_key", { key = "alt+w" })
-- ~/.config/alacritty/alacritty.yml:432
rex.bind("alt+x", "pane.send_key", { key = "alt+x" })
-- ~/.config/alacritty/alacritty.yml:433
rex.bind("alt+y", "pane.send_key", { key = "alt+y" })
-- ~/.config/alacritty/alacritty.yml:434
rex.bind("alt+z", "pane.send_key", { key = "alt+z" })
-- ~/.config/alacritty/alacritty.yml:435
rex.bind("alt+shift+a", "pane.send_key", { key = "alt+shift+a" })
-- ~/.config/alacritty/alacritty.yml:436
rex.bind("alt+shift+b", "pane.send_key", { key = "alt+shift+b" })
-- ~/.config/alacritty/alacritty.yml:437
rex.bind("alt+shift+c", "pane.send_key", { key = "alt+shift+c" })
-- ~/.config/alacritty/alacritty.yml:438
rex.bind("alt+shift+d", "pane.send_key", { key = "alt+shift+d" })
-- ~/.config/alacritty/alacritty.yml:439
rex.bind("alt+shift+e", "pane.send_key", { key = "alt+shift+e" })
-- ~/.config/alacritty/alacritty.yml:440
rex.bind("alt+shift+f", "pane.send_key", { key = "alt+shift+f" })
-- ~/.config/alacritty/alacritty.yml:441
rex.bind("alt+shift+g", "pane.send_key", { key = "alt+shift+g" })
-- ~/.config/alacritty/alacritty.yml:442
rex.bind("alt+shift+h", "pane.send_key", { key = "alt+shift+h" })
-- ~/.config/alacritty/alacritty.yml:443
rex.bind("alt+shift+i", "pane.send_key", { key = "alt+shift+i" })
-- ~/.config/alacritty/alacritty.yml:444
rex.bind("alt+shift+j", "pane.send_key", { key = "alt+shift+j" })
-- ~/.config/alacritty/alacritty.yml:445
rex.bind("alt+shift+k", "pane.send_key", { key = "alt+shift+k" })
-- ~/.config/alacritty/alacritty.yml:446
rex.bind("alt+shift+l", "pane.send_key", { key = "alt+shift+l" })
-- ~/.config/alacritty/alacritty.yml:447
rex.bind("alt+shift+m", "pane.send_key", { key = "alt+shift+m" })
-- ~/.config/alacritty/alacritty.yml:448
rex.bind("alt+shift+n", "pane.send_key", { key = "alt+shift+n" })
-- ~/.config/alacritty/alacritty.yml:449
rex.bind("alt+shift+o", "pane.send_key", { key = "alt+shift+o" })
-- ~/.config/alacritty/alacritty.yml:450
rex.bind("alt+shift+p", "pane.send_key", { key = "alt+shift+p" })
-- ~/.config/alacritty/alacritty.yml:451
rex.bind("alt+shift+q", "pane.send_key", { key = "alt+shift+q" })
-- ~/.config/alacritty/alacritty.yml:452
rex.bind("alt+shift+r", "pane.send_key", { key = "alt+shift+r" })
-- ~/.config/alacritty/alacritty.yml:453
rex.bind("alt+shift+s", "pane.send_key", { key = "alt+shift+s" })
-- ~/.config/alacritty/alacritty.yml:454
rex.bind("alt+shift+t", "pane.send_key", { key = "alt+shift+t" })
-- ~/.config/alacritty/alacritty.yml:455
rex.bind("alt+shift+u", "pane.send_key", { key = "alt+shift+u" })
-- ~/.config/alacritty/alacritty.yml:456
rex.bind("alt+shift+v", "pane.send_key", { key = "alt+shift+v" })
-- ~/.config/alacritty/alacritty.yml:457
rex.bind("alt+shift+w", "pane.send_key", { key = "alt+shift+w" })
-- ~/.config/alacritty/alacritty.yml:458
rex.bind("alt+shift+x", "pane.send_key", { key = "alt+shift+x" })
-- ~/.config/alacritty/alacritty.yml:459
rex.bind("alt+shift+y", "pane.send_key", { key = "alt+shift+y" })
-- ~/.config/alacritty/alacritty.yml:460
rex.bind("alt+shift+z", "pane.send_key", { key = "alt+shift+z" })
-- ~/.config/alacritty/alacritty.yml:461
rex.bind("alt+1", "pane.send_key", { key = "alt+1" })
-- ~/.config/alacritty/alacritty.yml:462
rex.bind("alt+2", "pane.send_key", { key = "alt+2" })
-- ~/.config/alacritty/alacritty.yml:463
rex.bind("alt+3", "pane.send_key", { key = "alt+3" })
-- ~/.config/alacritty/alacritty.yml:464
rex.bind("alt+4", "pane.send_key", { key = "alt+4" })
-- ~/.config/alacritty/alacritty.yml:465
rex.bind("alt+5", "pane.send_key", { key = "alt+5" })
-- ~/.config/alacritty/alacritty.yml:466
rex.bind("alt+6", "pane.send_key", { key = "alt+6" })
-- ~/.config/alacritty/alacritty.yml:467
rex.bind("alt+7", "pane.send_key", { key = "alt+7" })
-- ~/.config/alacritty/alacritty.yml:468
rex.bind("alt+8", "pane.send_key", { key = "alt+8" })
-- ~/.config/alacritty/alacritty.yml:469
rex.bind("alt+9", "pane.send_key", { key = "alt+9" })
-- ~/.config/alacritty/alacritty.yml:470
rex.bind("alt+0", "pane.send_key", { key = "alt+0" })
-- ~/.config/alacritty/alacritty.yml:472
rex.bind("alt+`", "pane.send_key", { key = "alt+`" })
-- ~/.config/alacritty/alacritty.yml:473
rex.bind("alt+shift+`", "pane.send_key", { key = "alt+shift+`" })
-- ~/.config/alacritty/alacritty.yml:474
rex.bind("alt+.", "pane.send_key", { key = "alt+." })
-- ~/.config/alacritty/alacritty.yml:475
rex.bind("alt+shift+8", "pane.send_key", { key = "alt+shift+8" })
-- ~/.config/alacritty/alacritty.yml:476
rex.bind("alt+shift+3", "pane.send_key", { key = "alt+shift+3" })
-- ~/.config/alacritty/alacritty.yml:477
rex.bind("alt+shift+.", "pane.send_key", { key = "alt+shift+." })
-- ~/.config/alacritty/alacritty.yml:478
rex.bind("alt+shift+,", "pane.send_key", { key = "alt+shift+," })
-- ~/.config/alacritty/alacritty.yml:479
rex.bind("alt+shift+-", "pane.send_key", { key = "alt+shift+-" })
-- ~/.config/alacritty/alacritty.yml:480
rex.bind("alt+shift+5", "pane.send_key", { key = "alt+shift+5" })
-- ~/.config/alacritty/alacritty.yml:481
rex.bind("alt+shift+6", "pane.send_key", { key = "alt+shift+6" })
-- ~/.config/alacritty/alacritty.yml:482
rex.bind("alt+\\", "pane.send_key", { key = "alt+\\" })
-- ~/.config/alacritty/alacritty.yml:483
rex.bind("alt+shift+\\", "pane.send_key", { key = "alt+shift+\\" })
-- ~/.config/alacritty/alacritty.yml:484
rex.bind("cmd+f1", "pane.send_key", { key = "alt+f1" })
-- ~/.config/alacritty/alacritty.yml:485
rex.bind("cmd+f2", "pane.send_key", { key = "alt+f2" })
-- ~/.config/alacritty/alacritty.yml:486
rex.bind("cmd+f3", "pane.send_key", { key = "alt+f3" })
-- ~/.config/alacritty/alacritty.yml:487
rex.bind("cmd+f4", "pane.send_key", { key = "alt+f4" })
-- ~/.config/alacritty/alacritty.yml:488
rex.bind("cmd+f5", "pane.send_key", { key = "alt+f5" })
-- ~/.config/alacritty/alacritty.yml:489
rex.bind("cmd+f6", "pane.send_key", { key = "alt+f6" })
-- ~/.config/alacritty/alacritty.yml:490
rex.bind("cmd+f7", "pane.send_key", { key = "alt+f7" })
-- ~/.config/alacritty/alacritty.yml:491
rex.bind("cmd+f8", "pane.send_key", { key = "alt+f8" })
-- ~/.config/alacritty/alacritty.yml:492
rex.bind("cmd+f9", "pane.send_key", { key = "alt+f9" })
-- ~/.config/alacritty/alacritty.yml:493
rex.bind("cmd+f10", "pane.send_key", { key = "alt+f10" })
-- ~/.config/alacritty/alacritty.yml:494
rex.bind("cmd+f11", "pane.send_key", { key = "alt+f11" })
-- ~/.config/alacritty/alacritty.yml:495
rex.bind("cmd+f12", "pane.send_key", { key = "alt+f12" })

-- Let Vim handle its own splits; navigate Rex panes in other programs.
local vim_programs = {
  vim = true, nvim = true, view = true, nview = true,
  vimdiff = true, nvimdiff = true, gvim = true, gview = true,
  gvimdiff = true, rvim = true, rview = true,
}

local function is_vim_process(process)
  for _, field in ipairs({ "name", "argv0", "path", "invoked_path" }) do
    local name = process[field]
    if type(name) == "string" then
      name = (name:match("([^/]+)$") or name):lower()
      if vim_programs[name] then return true end
    end
  end
  return false
end

rex.action{
  name = "vim_or_pane_focus",
  title = "Navigate Vim Split or Rex Pane",
  args = { key = "string" },
  run = function(ctx, args)
    local directions = { h = "left", j = "down", k = "up", l = "right" }
    local direction = directions[args.key]
    assert(direction, "Expected h, j, k, or l")
    local process = rex.block.call("com.superlogical.terminal", "process", {
      session_id = ctx.session_id, block_id = ctx.block_id,
    })
    -- If the foreground process cannot be identified, preserve terminal input.
    if not process or not process.foreground or is_vim_process(process.foreground) then
      rex.client.queue("pane.send_key", { key = "ctrl+" .. args.key })
    else
      rex.client.queue("pane.focus", { direction = direction })
    end
  end,
}

rex.bind("ctrl+h", "vim_or_pane_focus", { key = "h" })
rex.bind("ctrl+j", "vim_or_pane_focus", { key = "j" })
rex.bind("ctrl+k", "vim_or_pane_focus", { key = "k" })
rex.bind("ctrl+l", "vim_or_pane_focus", { key = "l" })

-- User-requested prefix shortcut for a new tab.
rex.bind("ctrl+space>shift+n", "client.tab.new")
