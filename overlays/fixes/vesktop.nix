# https://github.com/Vencord/Vesktop/issues/1413
# TODO: Remove once nixpkgs provides Vesktop >= 1.7.0
final: prev: {
  vesktop = prev.vesktop.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/renderer/patches/rpc.ts \
        --replace-fail 'setObservedGamesCallback\(\i,\i,(\i),\i\)\{' \
                       'setObservedGamesCallback\(\i,(\i),\i\)\{'
    '';
  });
}
