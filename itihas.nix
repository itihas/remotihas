localFlake:

{lib, config, self, inputs, ...}: {
  flake.nixosModules.itihas = {config, lib, pkgs, ...}: {
    users.users.itihas = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCQGNSPjJI9JAVyZsWP8uDSLMlZ+x2FSrOgfY1OpFL7+TDtHRfZ4C0kZajUCqPfhwuocjmVYKRB0+hvTku4Ma3VbuxeFIfX17JbRvNeAnA8mfhPR8YwutF6ufZABKQJBBTsKqYnfa8MeNowkpP3c7TPtcHvZHe+s6lf8XR42DngTtEmbAuGFMEP92IYUS0KWCNsliMB6gtuI/4LCZfyY2l9gFoCKkMOyS+MSYKVTDCR1Yh2T9TaZj3kMcodhv0AoLmqAQtD/SBXRA+zoFit/QHJKmRUoWB8kEXA3+H8XURdX8gKwZdQ3NP6spLZ69bjUVIq6j3wFXO+3ks2ynn79VBXQafjckOl89EzaMm88JnSfVD34G6LCls+y018DQK4qx/5gnNVueVgmaLDAhBmtK99yAWo6Et9r6g/xrQc6qzzMo29s2SJewTo+m7PFxIm3gZqM6PyXKrIVLRsBbG6Dv+ixJHXqoDXXVMjG3MxvclArpoyJKpDbaL3w/fPXuqoHx0= itihas@nixos"
      ];
    };
  };
}
